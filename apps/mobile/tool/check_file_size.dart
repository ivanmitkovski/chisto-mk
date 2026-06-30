// Run from apps/mobile: dart run tool/check_file_size.dart
// Optional: --stamp-baseline
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const int _hardLineLimit = 800;
const String _allowlistPath = 'tool/file_size_allowlist.txt';

const List<String> _skipSuffixes = <String>[
  '.g.dart',
  '.freezed.dart',
  'app_localizations.dart',
  'app_localizations_en.dart',
  'app_localizations_mk.dart',
  'app_localizations_sq.dart',
];

bool _shouldSkipFile(String normalizedPath) {
  for (final String suffix in _skipSuffixes) {
    if (normalizedPath.endsWith(suffix) ||
        normalizedPath.contains('app_localizations_')) {
      return true;
    }
  }
  return normalizedPath.contains('/.dart_tool/');
}

List<String> _scanOversizedFiles() {
  final List<String> hits = <String>[];
  for (final String root in allFeatureLibRoots()) {
    for (final File file in iterFeatureDartFiles(roots: <String>[root])) {
      final String normalized = normalizePath(file.path);
      if (_shouldSkipFile(normalized)) {
        continue;
      }
      final int lines = file.readAsLinesSync().length;
      if (lines > _hardLineLimit) {
        hits.add('$normalized:$lines');
      }
    }
  }
  // Also scan chisto_infrastructure + design_system presentation/data.
  for (final String extraRoot in <String>[
    'packages/chisto_infrastructure/lib',
    'packages/design_system/lib',
  ]) {
    final Directory dir = Directory(extraRoot);
    if (!dir.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String normalized = normalizePath(entity.path);
      if (_shouldSkipFile(normalized)) {
        continue;
      }
      final int lines = entity.readAsLinesSync().length;
      if (lines > _hardLineLimit) {
        hits.add('$normalized:$lines');
      }
    }
  }
  hits.sort();
  return hits;
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(allowlistPath: _allowlistPath, hits: _scanOversizedFiles());
    exit(0);
  }

  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'File size (hard >$_hardLineLimit lines)',
      hits: _scanOversizedFiles(),
      allowlistPath: _allowlistPath,
      fixHint: 'Decompose god files; allowlist only shrinks.',
    ),
  );
}
