// Run from apps/mobile: dart run tool/check_screen_size.dart
// Optional: dart run tool/check_screen_size.dart --stamp-baseline
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const int _hardLineLimit = 600;
const int _warnLineLimit = 400;
const String _allowlistPath = 'tool/screen_size_allowlist.txt';

bool _isScreenFile(String normalizedPath) {
  return isPresentationPath(normalizedPath) &&
      normalizedPath.contains('/screens/') &&
      normalizedPath.endsWith('_screen.dart');
}

List<String> _scanScreenSizes() {
  final List<String> hardViolations = <String>[];
  final List<String> warnings = <String>[];

  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    if (!_isScreenFile(normalized)) {
      continue;
    }
    final int lines = file.readAsLinesSync().length;
    if (lines > _hardLineLimit) {
      hardViolations.add('$normalized:$lines');
    } else if (lines > _warnLineLimit) {
      warnings.add('$normalized:$lines');
    }
  }

  if (warnings.isNotEmpty) {
    stderr.writeln(
      'Screen size warnings (${warnings.length}):\n${warnings.join('\n')}\n',
    );
  }

  return hardViolations..sort();
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(allowlistPath: _allowlistPath, hits: _scanScreenSizes());
    exit(0);
  }

  final List<String> hits = _scanScreenSizes();
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Screen size (hard >$_hardLineLimit)',
      hits: hits,
      allowlistPath: _allowlistPath,
      fixHint:
          'Extract coordinators/widgets; stamp baseline only when count decreases.',
    ),
  );
}
