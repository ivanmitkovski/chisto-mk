// Run from apps/mobile: dart run tool/check_no_magic_edge_insets_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const List<String> _skip = <String>[];

final RegExp _magicInsets = RegExp(
  r'EdgeInsets\.(all|symmetric|only|fromLTRB)\s*\([^)]*\d',
);

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> hits = scanDartRoots(
    roots: allFeatureLibRoots(),
    skipPathFragments: _skip,
    matchesLine: (String line) {
      if (!line.contains('EdgeInsets')) {
        return false;
      }
      if (line.contains('AppSpacing')) {
        return false;
      }
      return _magicInsets.hasMatch(line);
    },
  );
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: 'tool/magic_edge_insets_allowlist.txt',
      hits: hits,
    );
    exit(0);
  }
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Magic EdgeInsets literals',
      hits: hits,
      allowlistPath: 'tool/magic_edge_insets_allowlist.txt',
      fixHint: 'Use AppSpacing.* tokens in EdgeInsets.',
    ),
  );
}
