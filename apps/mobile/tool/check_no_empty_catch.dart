// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

/// Bans empty catch blocks in feature code.
int runNoEmptyCatchCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'Empty catch',
    hits: collectEmptyCatchHits(),
    allowlistPath: 'tool/empty_catch_allowlist.txt',
    fixHint: 'Log with AppLog.warn and optional Sentry breadcrumb',
  );
}

List<String> collectEmptyCatchHits() {
  final RegExp emptyCatch = RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}');
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    final String content = file.readAsStringSync();
    for (final RegExpMatch m in emptyCatch.allMatches(content)) {
      final int line = content.substring(0, m.start).split('\n').length;
      hits.add('$normalized:$line');
    }
  }
  return hits;
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: 'tool/empty_catch_allowlist.txt',
      hits: collectEmptyCatchHits(),
    );
    exit(0);
  }
  exit(runNoEmptyCatchCheck());
}
