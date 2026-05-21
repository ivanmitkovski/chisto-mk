// Run from apps/mobile: dart run tool/check_no_textstyle_in_features.dart
import 'dart:io';

const List<String> _scanRoots = <String>[
  'lib/features',
  'lib/shared',
];

final List<String> _skipPathFragments = <String>[
  'app_typography.dart',
  'report_tokens.dart',
];

/// Returns `0` when clean, `1` when violations found.
int runNoTextStyleInFeaturesCheck() {
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
      if (_skipPathFragments.any(entity.path.contains)) {
        continue;
      }
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (RegExp(r'\bTextStyle\(').hasMatch(lines[i])) {
          violations.add('${entity.path}:${i + 1}');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Forbidden TextStyle(…) outside theme token files:\n'
      '${violations.join('\n')}\n'
      'Use AppTypography tokens instead.',
    );
    return 1;
  }
  stdout.writeln('OK: no stray TextStyle(…) under features/ and shared/.');
  return 0;
}

void main() {
  exit(runNoTextStyleInFeaturesCheck());
}
