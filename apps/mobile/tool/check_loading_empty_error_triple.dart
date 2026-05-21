// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';

/// Screens should reference loading / empty / error affordances (ratchet allowlist).
int runLoadingEmptyErrorTripleCheck() {
  final Directory root = Directory('lib/features');
  final List<String> hits = <String>[];
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('_screen.dart')) continue;
    if (!e.path.contains('/presentation/screens/')) continue;
    final String content = e.readAsStringSync();
    final bool hasLoading = content.contains('Loading') ||
        content.contains('Skeleton') ||
        content.contains('AppLoadingIndicator');
    final bool hasEmpty = content.contains('Empty') || content.contains('empty');
    final bool hasError = content.contains('Error') || content.contains('error');
    if (!hasLoading || !hasEmpty || !hasError) {
      hits.add(e.path.replaceAll(r'\', '/'));
    }
  }
  return runRatchetingAllowlistCheck(
    patternDescription: 'Loading/empty/error triple',
    hits: hits,
    allowlistPath: 'tool/loading_empty_error_allowlist.txt',
    fixHint: 'Add AppLoadingIndicator, empty state widget, and inline error/retry',
  );
}

void main() {
  exit(runLoadingEmptyErrorTripleCheck());
}
