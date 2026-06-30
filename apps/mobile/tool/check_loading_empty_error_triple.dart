// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

/// Screens should reference loading / empty / error affordances (ratchet allowlist).
int runLoadingEmptyErrorTripleCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'Loading/empty/error triple',
    hits: collectLoadingEmptyErrorHits(),
    allowlistPath: 'tool/loading_empty_error_allowlist.txt',
    fixHint:
        'Add AppLoadingIndicator, empty state widget, and inline error/retry',
  );
}

List<String> collectLoadingEmptyErrorHits() {
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    if (!normalized.endsWith('_screen.dart')) {
      continue;
    }
    if (!normalized.contains('/presentation/screens/') &&
        !normalized.contains('/src/presentation/screens/')) {
      continue;
    }
    final String content = file.readAsStringSync();
    final bool hasLoading =
        content.contains('Loading') ||
        content.contains('Skeleton') ||
        content.contains('AppLoadingIndicator');
    final bool hasEmpty =
        content.contains('Empty') || content.contains('empty');
    final bool hasError =
        content.contains('Error') || content.contains('error');
    if (!hasLoading || !hasEmpty || !hasError) {
      hits.add(normalized);
    }
  }
  return hits;
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: 'tool/loading_empty_error_allowlist.txt',
      hits: collectLoadingEmptyErrorHits(),
    );
    exit(0);
  }
  exit(runLoadingEmptyErrorTripleCheck());
}
