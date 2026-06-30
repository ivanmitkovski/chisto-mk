// Run from apps/mobile: dart run tool/check_no_service_locator.dart
import 'dart:io';

import 'feature_roots_guard_util.dart';

const List<String> _banned = <String>['ServiceLocator', 'service_locator.dart'];

void main() {
  final List<String> violations = <String>[];

  for (final File file in iterFeatureDartFiles(roots: allAppCodeRoots())) {
    final String normalized = normalizePath(file.path);
    if (normalized.contains('core/bootstrap/app_bootstrap.dart')) {
      continue;
    }

    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      for (final String pattern in _banned) {
        if (line.contains(pattern)) {
          violations.add('$normalized:${i + 1}: banned `$pattern`');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'ServiceLocator ban failed (${violations.length}):\n${violations.join('\n')}',
    );
    exit(1);
  }

  stdout.writeln('No ServiceLocator references in app code.');
}
