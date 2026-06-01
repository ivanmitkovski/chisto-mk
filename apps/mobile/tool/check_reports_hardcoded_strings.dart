// Run from apps/mobile: dart tool/check_reports_hardcoded_strings.dart
// Optional: dart tool/check_reports_hardcoded_strings.dart --stamp-baseline
import 'dart:io';

import 'feature_roots_guard_util.dart';
import 'hardcoded_strings_guard_util.dart';

const String _baselinePath = 'tool/reports_hardcoded_english_baseline.txt';

int runHardcodedEnglishCheck({required bool stampBaseline}) {
  if (!Directory(reportsPackageRoot).existsSync()) {
    stderr.writeln('Run from apps/mobile');
    return 2;
  }
  return runHardcodedEnglishBaselineCheck(
    rootPaths: <String>[reportsPackageRoot],
    baselinePath: _baselinePath,
    stampBaseline: stampBaseline,
    skipDataLayer: true,
  );
}

void main(List<String> args) {
  final bool stamp = args.contains('--stamp-baseline');
  exit(runHardcodedEnglishCheck(stampBaseline: stamp));
}
