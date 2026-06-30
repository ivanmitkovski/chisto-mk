// Run from apps/mobile: dart run tool/check_no_raw_textfield_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const List<String> _skip = <String>[
  'shared/widgets/atoms/app_text_field.dart',
  'shared/widgets/atoms/auth_text_field.dart',
  'shared/widgets/atoms/profile_password_field.dart',
];

bool _matches(String line) {
  return RegExp(r'\bTextField\(').hasMatch(line) ||
      RegExp(r'\bTextFormField\(').hasMatch(line);
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
    stampAllowlist(
      allowlistPath: 'tool/raw_textfield_allowlist.txt',
      hits: hits,
    );
    exit(0);
  }
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Raw TextField/TextFormField',
      hits: hits,
      allowlistPath: 'tool/raw_textfield_allowlist.txt',
      fixHint: 'Use AppTextField or AuthTextField.',
    ),
  );
}
