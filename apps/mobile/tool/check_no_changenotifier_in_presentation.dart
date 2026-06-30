// Run from apps/mobile: dart run tool/check_no_changenotifier_in_presentation.dart
// Optional: --stamp-baseline
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const String _allowlistPath = 'tool/changenotifier_presentation_allowlist.txt';

bool _isApplicationOrPresentation(String normalizedPath) {
  return isPresentationPath(normalizedPath) ||
      isApplicationPath(normalizedPath);
}

bool _matchesChangeNotifierLine(String line) {
  if (line.trimLeft().startsWith('//')) {
    return false;
  }
  return line.contains('extends ChangeNotifier') ||
      line.contains('extends StateNotifier') ||
      line.contains('with ChangeNotifier');
}

List<String> _scanChangeNotifierInPresentation() {
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    if (!_isApplicationOrPresentation(normalized)) {
      continue;
    }
    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (_matchesChangeNotifierLine(lines[i])) {
        hits.add('$normalized:${i + 1}');
      }
    }
  }
  return hits;
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: _allowlistPath,
      hits: _scanChangeNotifierInPresentation(),
    );
    exit(0);
  }

  exit(
    runRatchetingAllowlistCheck(
      patternDescription:
          'ChangeNotifier/StateNotifier in presentation/application',
      hits: _scanChangeNotifierInPresentation(),
      allowlistPath: _allowlistPath,
      fixHint:
          'Migrate to @riverpod Notifier/AsyncNotifier; allowlist only shrinks.',
    ),
  );
}
