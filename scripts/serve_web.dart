// Minimal static file server for `flutter build web` output.
//
//   dart scripts/serve_web.dart -p 5599 -d build/web
//
// It exists so the local screenshot pipeline can render a production build
// without a debug-service WebSocket keeping the headless browser "busy".
import 'dart:io';

Future<void> main(List<String> args) async {
  int port = 5599;
  String root = 'build/web';
  for (int i = 0; i < args.length - 1; i++) {
    if (args[i] == '-p' || args[i] == '--port') port = int.parse(args[i + 1]);
    if (args[i] == '-d' || args[i] == '--dir') root = args[i + 1];
  }

  final Directory dir = Directory(root).absolute;
  if (!dir.existsSync()) {
    stderr.writeln('directory not found: ${dir.path}');
    exitCode = 2;
    return;
  }

  final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('serving ${dir.path} on http://127.0.0.1:$port/');

  await for (final HttpRequest request in server) {
    final String path = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final File file = File('${dir.path}$path');
    try {
      if (await file.exists()) {
        request.response.headers.contentType = _contentType(path);
        request.response.headers.set('cache-control', 'no-store');
        await request.response.addStream(file.openRead());
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('not found: $path');
      }
    } catch (error) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('$error');
    } finally {
      await request.response.close();
    }
  }
}

ContentType _contentType(String path) {
  final String ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'html':
      return ContentType.html;
    case 'js':
    case 'mjs':
      return ContentType('application', 'javascript', charset: 'utf-8');
    case 'json':
      return ContentType.json;
    case 'css':
      return ContentType('text', 'css', charset: 'utf-8');
    case 'wasm':
      return ContentType('application', 'wasm');
    case 'png':
      return ContentType('image', 'png');
    case 'jpg':
    case 'jpeg':
      return ContentType('image', 'jpeg');
    case 'svg':
      return ContentType('image', 'svg+xml');
    case 'ico':
      return ContentType('image', 'x-icon');
    case 'ttf':
      return ContentType('font', 'ttf');
    case 'otf':
      return ContentType('font', 'otf');
    case 'woff':
      return ContentType('font', 'woff');
    case 'woff2':
      return ContentType('font', 'woff2');
    case 'map':
      return ContentType('application', 'json', charset: 'utf-8');
    default:
      return ContentType.binary;
  }
}
