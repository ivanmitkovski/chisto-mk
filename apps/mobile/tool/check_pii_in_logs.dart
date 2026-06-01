// ignore_for_file: avoid_print
import 'dart:io';

import 'feature_roots_guard_util.dart';

/// Fails if AppLog.warn/error messages embed obvious PII patterns.
void main() {
  final RegExp pii = RegExp(
    r'AppLog\.(warn|error)\([^)]*(@|\+\d{6,}|Bearer\s|accessToken|refreshToken|\bpassword\b)',
    caseSensitive: false,
  );
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allAppCodeRoots())) {
    final String normalized = normalizePath(file.path);
    final String content = file.readAsStringSync();
    for (final RegExpMatch m in pii.allMatches(content)) {
      hits.add('$normalized: ${m.group(0)}');
    }
  }
  if (hits.isNotEmpty) {
    stderr.writeln('check_pii_in_logs: possible PII in log messages:');
    for (final String h in hits) {
      stderr.writeln('  $h');
    }
    exit(1);
  }
  print('check_pii_in_logs: OK');
}
