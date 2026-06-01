// Usage: dart run tool/check_reports_max_lines.dart
// Fails if any Dart file under feature_reports exceeds [maxLines].

import 'dart:io';

import 'feature_roots_guard_util.dart';

const int maxLines = 800;

Future<void> main(List<String> args) async {
  final Directory root = Directory(reportsPackageRoot);
  if (!await root.exists()) {
    stderr.writeln('Missing ${root.path}');
    exitCode = 1;
    return;
  }
  final List<String> violations = <String>[];
  await for (final FileSystemEntity e in root.list(
    recursive: true,
    followLinks: false,
  )) {
    if (e is! File || !e.path.endsWith('.dart')) {
      continue;
    }
    final int n = await e.readAsLines().then((List<String> l) => l.length);
    if (n > maxLines) {
      violations.add('${e.path}: $n lines (max $maxLines)');
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(
      'Reports feature file(s) exceed $maxLines lines:\n${violations.join('\n')}',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('OK: all reports Dart files are at most $maxLines lines.');
}
