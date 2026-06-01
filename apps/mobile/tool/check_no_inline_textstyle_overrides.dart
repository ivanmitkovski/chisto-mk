// Run from apps/mobile: dart run tool/check_no_inline_textstyle_overrides.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

List<String> _featureAndSharedRoots() => allFeatureLibRoots();

const List<String> _skip = <String>[
  'app_typography.dart',
  'report_tokens.dart',
  'app_surface/',
];

final RegExp _inlineOverride = RegExp(
  r'Theme\.of\([^)]+\)\.textTheme\.[a-zA-Z]+\?\.copyWith\(',
);

bool _matches(String line) => _inlineOverride.hasMatch(line);

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> hits = scanDartRoots(
    roots: _featureAndSharedRoots(),
    skipPathFragments: _skip,
    matchesLine: _matches,
  );
  final bool stamp = args.contains('--stamp-baseline');
  if (stamp) {
    const String path = 'tool/inline_textstyle_override_allowlist.txt';
    File(path).writeAsStringSync('${hits.join('\n')}\n');
    stdout.writeln('Wrote ${hits.length} lines to $path');
    exit(0);
  }
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Inline textTheme.copyWith override',
      hits: hits,
      allowlistPath: 'tool/inline_textstyle_override_allowlist.txt',
      fixHint:
          'Use AppTypography.*(Theme.of(context).textTheme) helpers instead.',
    ),
  );
}
