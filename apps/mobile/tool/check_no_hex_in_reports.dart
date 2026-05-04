// Run from apps/mobile: dart run tool/check_no_hex_in_reports.dart
import 'dart:io';

/// Returns `0` when clean, `1` when violations found, `2` when reports tree missing.
int runNoHexInReportsCheck() {
  final Directory root = Directory('lib/features/reports');
  if (!root.existsSync()) {
    stderr.writeln('Directory ${root.path} not found (run from apps/mobile).');
    return 2;
  }

  final List<String> violations = <String>[];
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final List<String> lines = entity.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('Color(0x')) {
        violations.add('${entity.path}:${i + 1}');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Forbidden Color(0x…) literal under lib/features/reports/:\n'
      '${violations.join('\n')}\n'
      'Use AppColors / ReportStatusPalette tokens instead.',
    );
    return 1;
  }
  stdout.writeln('OK: no Color(0x…) in lib/features/reports/.');
  return 0;
}

void main() {
  exit(runNoHexInReportsCheck());
}
