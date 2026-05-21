// Run from apps/mobile: dart run tool/check_no_raw_shadow_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';

const List<String> _roots = <String>['lib/features', 'lib/shared'];
const List<String> _skip = <String>[
  'core/theme/',
  'app_shadows.dart',
  'app_card_chrome.dart',
];

void main() {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> hits = scanDartRoots(
    roots: _roots,
    skipPathFragments: _skip,
    matchesLine: (String line) => line.contains('BoxShadow('),
  );
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Raw BoxShadow',
      hits: hits,
      allowlistPath: 'tool/raw_shadow_allowlist.txt',
      fixHint: 'Use AppShadows.* from core/theme/app_shadows.dart.',
    ),
  );
}
