// ignore_for_file: avoid_print

import 'dart:io';

import 'feature_roots_guard_util.dart';

/// Bans [AuthState.setUnauthenticated] outside core/auth and features/auth.
int runNoDirectSetUnauthenticatedInFeaturesCheck() {
  const Set<String> allowedFragments = <String>{
    'core/auth/',
    'core/bootstrap/',
    'packages/feature_auth/lib/src/',
  };
  final RegExp call = RegExp(r'\.setUnauthenticated\s*\(');
  final List<String> violations = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allAppCodeRoots())) {
    final String normalized = normalizePath(file.path);
    if (allowedFragments.any(normalized.contains)) {
      continue;
    }
    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String ln = lines[i];
      if (ln.trim().startsWith('//')) {
        continue;
      }
      if (call.hasMatch(ln)) {
        violations.add('$normalized:${i + 1}: $ln');
      }
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(
      'Direct setUnauthenticated() in feature code (use ApiClient / onAuthRejected):\n'
      '${violations.join('\n')}',
    );
    return 1;
  }
  stdout.writeln('OK: no direct setUnauthenticated() outside auth modules.');
  return 0;
}

void main() {
  exit(runNoDirectSetUnauthenticatedInFeaturesCheck());
}
