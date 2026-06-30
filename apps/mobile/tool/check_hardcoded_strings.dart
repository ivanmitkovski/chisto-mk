// Run from apps/mobile: dart tool/check_hardcoded_strings.dart
// Optional: dart tool/check_hardcoded_strings.dart --stamp-baseline
import 'dart:io';

import 'check_reports_hardcoded_strings.dart' as reports_scan;
import 'hardcoded_strings_guard_util.dart';

const String _baselinePath = 'tool/hardcoded_english_baseline.txt';

const List<String> _roots = <String>[
  'packages/feature_home/lib/src/presentation',
  'packages/feature_profile/lib/src/presentation',
  'packages/feature_events/lib/src/presentation',
  'packages/feature_safety/lib/src/presentation',
  'packages/feature_onboarding/lib/src/presentation',
];

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('Run from apps/mobile');
    exit(2);
  }

  final bool stamp = args.contains('--stamp-baseline');
  final int code = runHardcodedEnglishBaselineCheck(
    rootPaths: _roots,
    baselinePath: _baselinePath,
    stampBaseline: stamp,
    okMessage:
        'OK: presentation hardcoded English baseline (${File(_baselinePath).existsSync() ? File(_baselinePath).readAsLinesSync().where((String l) => l.trim().isNotEmpty).length : 0} entries).',
  );
  if (code != 0) {
    exit(code);
  }
  if (stamp) {
    exit(0);
  }

  final int reportsCode = reports_scan.runHardcodedEnglishCheck(
    stampBaseline: false,
  );
  exit(reportsCode);
}
