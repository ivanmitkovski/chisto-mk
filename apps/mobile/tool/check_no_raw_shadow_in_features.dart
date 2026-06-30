// Run from apps/mobile: dart run tool/check_no_raw_shadow_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

List<String> _featureAndSharedRoots() => allFeatureLibRoots();

const List<String> _skip = <String>[
  'core/theme/',
  'app_shadows.dart',
  'app_card_chrome.dart',
];

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> hits = scanDartRoots(
    roots: _featureAndSharedRoots(),
    skipPathFragments: _skip,
    matchesLine: (String line) => line.contains('BoxShadow('),
  );
  if (wantsStampBaseline(args)) {
    stampAllowlist(allowlistPath: 'tool/raw_shadow_allowlist.txt', hits: hits);
    exit(0);
  }
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Raw BoxShadow',
      hits: hits,
      allowlistPath: 'tool/raw_shadow_allowlist.txt',
      fixHint: 'Use AppShadows.* from core/theme/app_shadows.dart.',
    ),
  );
}
