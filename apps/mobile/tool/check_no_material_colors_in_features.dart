// Run from apps/mobile: dart run tool/check_no_material_colors_in_features.dart
import 'dart:io';

const List<String> _scanRoots = <String>[
  'lib/features',
  'lib/shared',
];

/// Paths that may use Material [Colors] for true transparency / video chrome only.
final List<String> _allowlistPathFragments = <String>[
  // None by default — migrate to AppColors; add only with comment in PR.
];

/// Returns `0` when clean, `1` when violations found.
int runNoMaterialColorsInFeaturesCheck() {
  final List<String> violations = <String>[];
  for (final String rootPath in _scanRoots) {
    final Directory root = Directory(rootPath);
    if (!root.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (_allowlistPathFragments.any(entity.path.contains)) {
        continue;
      }
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (RegExp(r'\bColors\.').hasMatch(lines[i])) {
          violations.add('${entity.path}:${i + 1}');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Forbidden Material Colors.* outside allowlist:\n'
      '${violations.join('\n')}\n'
      'Use AppColors / ColorScheme tokens instead.',
    );
    return 1;
  }
  stdout.writeln('OK: no Material Colors.* under features/ and shared/.');
  return 0;
}

void main() {
  exit(runNoMaterialColorsInFeaturesCheck());
}
