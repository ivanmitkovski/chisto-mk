// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';

final RegExp _magicInsets = RegExp(
  r'EdgeInsets\.(all|symmetric|only|fromLTRB)\s*\([^)]*\d',
);

void main() {
  final List<String> hits = scanDartRoots(
    roots: <String>['lib/features'],
    skipPathFragments: <String>[],
    matchesLine: (String line) {
      if (!line.contains('EdgeInsets') || line.contains('AppSpacing')) {
        return false;
      }
      return _magicInsets.hasMatch(line);
    },
  )..sort();
  File('tool/magic_edge_insets_allowlist.txt').writeAsStringSync(
    '${hits.join('\n')}\n',
  );
  print('wrote ${hits.length} allowlist entries');
}
