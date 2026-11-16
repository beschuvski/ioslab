// validate_workflows.dart - structural validation for GitHub Actions workflows.
//
// GitHub is not reachable from this machine's web endpoint, so actionlint can
// not be downloaded. This script performs the checks that matter for catching
// broken YAML before pushing: parsing, top-level keys, job shape, runs-on,
// steps, and that every `uses:` reference is version-pinned.
//
// Run with the Flutter tool's package configuration (it already depends on
// package:yaml), or from a package that depends on yaml:
//
//   dart --packages=<flutter>/packages/flutter_tools/.dart_tool/package_config.json \
//        scripts/validate_workflows.dart .github/workflows/ios.yml
import 'dart:io';

import 'package:yaml/yaml.dart';

int _errors = 0;

void main(List<String> args) {
  final List<String> files = args.isEmpty
      ? Directory('.github/workflows')
          .listSync()
          .whereType<File>()
          .map((File f) => f.path)
          .where((String p) => p.endsWith('.yml') || p.endsWith('.yaml'))
          .toList()
      : args;

  for (final String path in files) {
    _validate(File(path));
  }

  if (_errors > 0) {
    stderr.writeln('${_errors} problem(s) found');
    exitCode = 1;
  } else {
    stdout.writeln('all workflow files are structurally valid');
  }
}

void _validate(File file) {
  stdout.writeln('checking ${file.path}');
  if (!file.existsSync()) {
    _error(file, 'file does not exist');
    return;
  }
  final String source = file.readAsStringSync();
  if (source.contains('\t')) {
    _error(file, 'contains a tab character (YAML forbids tabs for indentation)');
  }

  dynamic doc;
  try {
    doc = loadYamlNode(source);
  } on YamlException catch (e) {
    _error(file, 'YAML parse error: ${e.message}');
    return;
  }
  if (doc is! YamlMap) {
    _error(file, 'root node is not a mapping');
    return;
  }

  final Map<dynamic, dynamic> root = doc;
  if (!root.containsKey('on')) _error(file, 'missing "on" trigger');
  if (!root.containsKey('jobs')) {
    _error(file, 'missing "jobs"');
    return;
  }

  final dynamic jobs = root['jobs'];
  if (jobs is! YamlMap || jobs.isEmpty) {
    _error(file, '"jobs" must be a non-empty mapping');
    return;
  }

  for (final dynamic entry in jobs.entries) {
    final String jobId = entry.key as String;
    final dynamic job = entry.value;
    if (job is! YamlMap) {
      _error(file, 'job "$jobId" is not a mapping');
      continue;
    }
    final dynamic runsOn = job['runs-on'];
    if (runsOn == null) {
      _error(file, 'job "$jobId" has no runs-on');
    } else if (runsOn is String && !runsOn.contains('macos')) {
      // Not an error for generic workflows, but this repository is iOS-only.
      stdout.writeln('  note: job "$jobId" runs on "$runsOn" (not macOS)');
    }

    final dynamic steps = job['steps'];
    if (steps is! YamlList || steps.isEmpty) {
      _error(file, 'job "$jobId" has no steps');
      continue;
    }
    for (int i = 0; i < steps.length; i++) {
      final dynamic step = steps[i];
      if (step is! YamlMap) {
        _error(file, 'job "$jobId" step #$i is not a mapping');
        continue;
      }
      final dynamic uses = step['uses'];
      if (uses is String) {
        if (!RegExp(r'@[^@\s]+$').hasMatch(uses)) {
          _error(file, 'job "$jobId" step #$i uses "$uses" without a version tag');
        }
        if (uses.startsWith('actions/') && uses.contains('@v4')) {
          // keep the note short; v4 is current for checkout/upload-artifact
        }
      } else if (step['run'] == null) {
        _error(file, 'job "$jobId" step #$i has neither "uses" nor "run"');
      }
    }
  }
  stdout.writeln('  ok: ${jobs.length} job(s)');
}

void _error(File file, String message) {
  _errors++;
  stderr.writeln('  ERROR ${file.path}: $message');
}
