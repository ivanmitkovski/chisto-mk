// Run from apps/mobile: dart run tool/check_no_raw_snackbar_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const List<String> _skip = <String>['shared/widgets/atoms/app_snack.dart'];

void main() {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> hits = scanDartRoots(
    roots: allFeatureLibRoots(),
    skipPathFragments: _skip,
    matchesLine: (String line) => line.contains('showSnackBar('),
  );
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Raw showSnackBar',
      hits: hits,
      allowlistPath: 'tool/raw_snackbar_allowlist.txt',
      fixHint: 'Use AppSnack.show from shared/widgets/atoms/app_snack.dart.',
    ),
  );
}
