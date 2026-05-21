// Run from apps/mobile: dart run tool/check_no_hex_in_features.dart
import 'dart:io';

const List<String> _scanRoots = <String>[
  'lib/features/home',
  'lib/features/events',
  'lib/shared',
  'lib/features/reports',
];

/// Returns `0` when clean, `1` when violations found.
int runNoHexInFeaturesCheck() {
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
      if (entity.path.contains('${Platform.pathSeparator}app_colors.dart')) {
        continue;
      }
      if (entity.path.contains('${Platform.pathSeparator}report_tokens.dart')) {
        continue;
      }
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('Color(0x')) {
          violations.add('${entity.path}:${i + 1}');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Forbidden Color(0x…) outside theme token files:\n'
      '${violations.join('\n')}\n'
      'Use AppColors / AppTypography tokens instead.',
    );
    return 1;
  }
  stdout.writeln('OK: no stray Color(0x…) under home/events/shared/reports features.');
  return 0;
}

void main() {
  exit(runNoHexInFeaturesCheck());
}
