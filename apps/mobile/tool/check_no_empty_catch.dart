// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';

/// Bans empty catch blocks in features/.
int runNoEmptyCatchCheck() {
  final Directory root = Directory('lib/features');
  final RegExp emptyCatch = RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}');
  final List<String> hits = <String>[];
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final String content = e.readAsStringSync();
    for (final RegExpMatch m in emptyCatch.allMatches(content)) {
      final int line = content.substring(0, m.start).split('\n').length;
      hits.add('${e.path}:$line');
    }
  }
  return runRatchetingAllowlistCheck(
    patternDescription: 'Empty catch',
    hits: hits,
    allowlistPath: 'tool/empty_catch_allowlist.txt',
    fixHint: 'Log with AppLog.warn and optional Sentry breadcrumb',
  );
}

void main() {
  exit(runNoEmptyCatchCheck());
}
