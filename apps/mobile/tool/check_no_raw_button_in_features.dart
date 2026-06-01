// Run from apps/mobile: dart run tool/check_no_raw_button_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const List<String> _skip = <String>[
  'shared/widgets/atoms/app_button.dart',
  'shared/widgets/atoms/primary_button.dart',
  'shared/widgets/organisms/auth_shell.dart',
];

bool _matches(String line) {
  return line.contains('FilledButton(') ||
      line.contains('ElevatedButton(') ||
      line.contains('OutlinedButton(') ||
      line.contains('TextButton(');
}

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> hits = scanDartRoots(
    roots: allFeatureLibRoots(),
    skipPathFragments: _skip,
    matchesLine: _matches,
  );
  if (wantsStampBaseline(args)) {
    stampAllowlist(allowlistPath: 'tool/raw_button_allowlist.txt', hits: hits);
    exit(0);
  }
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Raw Material button',
      hits: hits,
      allowlistPath: 'tool/raw_button_allowlist.txt',
      fixHint: 'Use AppButton from shared/widgets/atoms/app_button.dart.',
    ),
  );
}
