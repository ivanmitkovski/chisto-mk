import 'dart:io';

import 'feature_roots_guard_util.dart';

const List<String> _skipPathFragments = <String>[
  'app_typography.dart',
  'app_typography_surfaces.dart',
  'report_tokens.dart',
];

const List<String> _tokenFileSuffixes = <String>[
  '/theme/app_typography.dart',
  '/theme/app_typography_surfaces.dart',
];

bool _isTokenFile(String normalizedPath) {
  if (_skipPathFragments.any(normalizedPath.contains)) {
    return true;
  }
  return _tokenFileSuffixes.any(normalizedPath.endsWith);
}

List<String> _readAllowlist(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    return <String>[];
  }
  return file
      .readAsLinesSync()
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
}

bool _isAllowlisted(String hit, List<String> allowlist) {
  for (final String entry in allowlist) {
    if (hit.startsWith(entry)) {
      return true;
    }
  }
  return false;
}

/// Returns `0` when clean, `1` when violations found.
int runTypographyGuardCheck() {
  final List<String> allowlist = _readAllowlist(
    'tool/typography_allowlist.txt',
  );
  final List<String> violations = <String>[];

  for (final File file in iterFeatureDartFiles(
    roots: allAppCodeRoots(),
    skipPathFragments: _skipPathFragments,
  )) {
    final String normalized = normalizePath(file.path);
    if (_isTokenFile(normalized)) {
      continue;
    }

    if (_isTokenFile(normalized)) {
      continue;
    }
    if (normalized.endsWith('/app_theme.dart')) {
      continue;
    }

    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String hit = '$normalized:${i + 1}';

      if (RegExp(r'\bTextStyle\(').hasMatch(line)) {
        violations.add('$hit: raw TextStyle(');
      }
      if (RegExp(r'\bfontFamily\s*:').hasMatch(line) &&
          !line.contains('IconData') &&
          !line.contains('MaterialIcons') &&
          !line.contains('avatarInitials')) {
        violations.add('$hit: fontFamily:');
      }
    }
  }

  final List<String> filtered = violations
      .where((String hit) => !_isAllowlisted(hit, allowlist))
      .toList();

  if (filtered.isNotEmpty) {
    stderr.writeln(
      'Typography guard violations (use AppTypography / AppText tokens):\n'
      '${filtered.join('\n')}\n'
      'See design_system/lib/src/theme/app_typography.dart and AppText.',
    );
    return 1;
  }
  stdout.writeln('OK: typography guard clean.');
  return 0;
}

/// Legacy entrypoint name kept for CI scripts.
int runNoTextStyleInFeaturesCheck() => runTypographyGuardCheck();

void main() {
  exit(runTypographyGuardCheck());
}
