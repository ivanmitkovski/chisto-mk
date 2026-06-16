// Run from apps/mobile: dart run tool/check_no_raw_bottom_sheet_in_features.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const List<String> _skip = <String>['site_comments_modal_bottom_sheet.dart'];

bool _matches(String line) {
  return line.contains('showModalBottomSheet(') ||
      line.contains('DraggableScrollableSheet(');
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
      allowlistPath: 'tool/raw_bottom_sheet_allowlist.txt',
      hits: hits,
    );
    exit(0);
  }
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Raw bottom sheet host',
      hits: hits,
      allowlistPath: 'tool/raw_bottom_sheet_allowlist.txt',
      fixHint:
          'Use AppBottomSheet.show or AppBottomSheet.showResizable from design_system.',
    ),
  );
}
