// Run from apps/mobile: dart run tool/check_no_raw_radius_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

List<String> _featureAndSharedRoots() => allFeatureLibRoots();

const List<String> _skip = <String>[
  'app_radii.dart',
  'app_spacing.dart',
  'app_card_chrome.dart',
  'app_input_outline.dart',
];

final RegExp _literalRadius = RegExp(r'BorderRadius\.circular\(\s*\d');

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> hits = scanDartRoots(
    roots: _featureAndSharedRoots(),
    skipPathFragments: _skip,
    matchesLine: _literalRadius.hasMatch,
  );
  if (wantsStampBaseline(args)) {
    stampAllowlist(allowlistPath: 'tool/raw_radius_allowlist.txt', hits: hits);
    exit(0);
  }
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Literal BorderRadius.circular',
      hits: hits,
      allowlistPath: 'tool/raw_radius_allowlist.txt',
      fixHint: 'Use AppRadii.* or AppSpacing.radius* tokens.',
    ),
  );
}
