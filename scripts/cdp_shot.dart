// cdp_shot.dart - deterministic, native-resolution screenshots of a web page.
//
// Chromium's `--screenshot` flag cannot express "393 x 852 CSS pixels at 3x"
// (window sizes are clamped and device-scale-factor does not change the CSS
// viewport), so this script drives the DevTools Protocol instead:
//
//   Emulation.setDeviceMetricsOverride(width: 393, height: 852, dsf: 3)
//   Page.navigate -> Page.loadEventFired -> Page.captureScreenshot
//
// Usage:
//   dart scripts/cdp_shot.dart --url http://127.0.0.1:5599/ \
//        --out artifacts/screenshots/local.png [--width 393] [--height 852]
//        [--scale 3] [--edge "C:\...\msedge.exe"]
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> argv) async {
  final Map<String, String> args = _parseArgs(argv);
  final String url = args['url'] ?? 'http://127.0.0.1:5599/';
  final String out = args['out'] ?? 'screenshot.png';
  final int width = int.tryParse(args['width'] ?? '') ?? 393;
  final int height = int.tryParse(args['height'] ?? '') ?? 852;
  final double scale = double.tryParse(args['scale'] ?? '') ?? 3.0;
  final String edge = args['edge'] ?? _defaultEdge();

  if (!File(edge).existsSync()) {
    stderr.writeln('Edge not found: $edge');
    exitCode = 2;
    return;
  }

  final int port = await _freePort();
  final Directory profile = Directory.systemTemp.createTempSync('cdp-shot-');
  final Process browser = await Process.start(edge, <String>[
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-extensions',
    '--mute-audio',
    '--remote-debugging-port=$port',
    '--user-data-dir=${profile.path}',
    'about:blank',
  ]);

  Cdp? cdp;
  try {
    final Uri endpoint = await _waitForEndpoint(port);
    cdp = await Cdp.connect(endpoint);
    await cdp.send('Page.enable');
    await cdp.send('Runtime.enable');
    await cdp.send('Emulation.setDeviceMetricsOverride', <String, Object?>{
      'width': width,
      'height': height,
      'deviceScaleFactor': scale,
      'mobile': true,
      'screenWidth': width,
      'screenHeight': height,
    });
    await cdp.send('Emulation.setTouchEmulationEnabled', <String, Object?>{
      'enabled': true,
      'maxTouchPoints': 5,
    });

    final Completer<void> loaded = Completer<void>();
    cdp.events.listen((Map<String, dynamic> event) {
      if (event['method'] == 'Page.loadEventFired' && !loaded.isCompleted) {
        loaded.complete();
      }
    });

    await cdp.send('Page.navigate', <String, Object?>{'url': url});
    await loaded.future.timeout(const Duration(seconds: 40));

    // Wait for web fonts, then for Flutter's first frames.
    await cdp.send('Runtime.evaluate', <String, Object?>{
      'expression': 'document.fonts.ready.then(() => true)',
      'awaitPromise': true,
      'returnByValue': true,
    });
    await Future<void>.delayed(const Duration(milliseconds: 2500));

    final Map<String, dynamic> shot = await cdp.send(
      'Page.captureScreenshot',
      <String, Object?>{'format': 'png', 'fromSurface': true},
    );
    final String base64 = (shot['result'] as Map<String, dynamic>)['data'] as String;
    final File file = File(out)..parent.createSync(recursive: true);
    file.writeAsBytesSync(base64Decode(base64));
    stdout.writeln('${file.path} (${width * scale.toInt()}x${height * scale.toInt()} px)');
  } finally {
    await cdp?.close();
    browser.kill(ProcessSignal.sigkill);
    try {
      profile.deleteSync(recursive: true);
    } catch (_) {}
  }
}

Map<String, String> _parseArgs(List<String> argv) {
  final Map<String, String> out = <String, String>{};
  for (int i = 0; i < argv.length - 1; i++) {
    if (argv[i].startsWith('--')) {
      out[argv[i].substring(2)] = argv[i + 1];
      i++;
    }
  }
  return out;
}

String _defaultEdge() {
  const List<String> candidates = <String>[
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
  ];
  for (final String path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return candidates.first;
}

Future<int> _freePort() async {
  final ServerSocket socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final int port = socket.port;
  await socket.close();
  return port;
}

Future<Uri> _waitForEndpoint(int port) async {
  final HttpClient client = HttpClient();
  final Stopwatch watch = Stopwatch()..start();
  while (watch.elapsed < const Duration(seconds: 30)) {
    try {
      final HttpClientRequest request = await client.openUrl(
        'PUT',
        Uri.parse('http://127.0.0.1:$port/json/new?about:blank'),
      );
      request.headers.set('Content-Type', 'application/json');
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final Map<String, dynamic> target = jsonDecode(body) as Map<String, dynamic>;
        return Uri.parse(target['webSocketDebuggerUrl'] as String);
      }
    } catch (_) {
      // browser is still starting
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('DevTools endpoint did not become available on port $port');
}

class Cdp {
  Cdp._(this._socket) {
    _socket.listen(
      (dynamic data) {
        final Map<String, dynamic> message = jsonDecode(data as String) as Map<String, dynamic>;
        final Object? id = message['id'];
        if (id is int) {
          final Completer<Map<String, dynamic>>? completer = _pending.remove(id);
          completer?.complete(message);
        } else if (message['method'] is String) {
          _events.add(message);
        }
      },
      onDone: () {
        for (final Completer<Map<String, dynamic>> c in _pending.values) {
          if (!c.isCompleted) {
            c.completeError(StateError('DevTools connection closed'));
          }
        }
        _pending.clear();
      },
    );
  }

  final WebSocket _socket;
  final Map<int, Completer<Map<String, dynamic>>> _pending =
      <int, Completer<Map<String, dynamic>>>{};
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  int _nextId = 0;

  static Future<Cdp> connect(Uri endpoint) async {
    final WebSocket socket = await WebSocket.connect(endpoint.toString());
    return Cdp._(socket);
  }

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<Map<String, dynamic>> send(String method, [Map<String, Object?>? params]) async {
    final int id = ++_nextId;
    final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _socket.add(jsonEncode(<String, Object?>{
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    }));
    final Map<String, dynamic> response =
        await completer.future.timeout(const Duration(seconds: 60));
    final Object? error = response['error'];
    if (error != null) {
      throw StateError('$method failed: $error');
    }
    return response;
  }

  Future<void> close() async {
    await _socket.close();
    await _events.close();
  }
}
