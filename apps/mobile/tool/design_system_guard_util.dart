import 'dart:io';

/// Shared ratcheting allowlist logic for design-system CI guards.
bool get designSystemStrictMode =>
    Platform.environment['DESIGN_SYSTEM_STRICT'] == 'true' ||
    Platform.environment['DESIGN_SYSTEM_STRICT'] == '1';

int runRatchetingAllowlistCheck({
  required String patternDescription,
  required List<String> hits,
  required String allowlistPath,
  required String fixHint,
}) {
  hits.sort();

  if (designSystemStrictMode) {
    if (hits.isNotEmpty) {
      stderr.writeln(
        '$patternDescription STRICT mode: ${hits.length} violation(s):\n'
        '${hits.join('\n')}\n$fixHint',
      );
      return 1;
    }
    stdout.writeln('$patternDescription STRICT check passed (0 violations).');
    return 0;
  }

  final File allowlistFile = File(allowlistPath);
  if (!allowlistFile.existsSync()) {
    stderr.writeln(
      'Missing $allowlistPath — create with one path:line per hit (sorted).\n'
      'Current hits (${hits.length}):\n${hits.join('\n')}',
    );
    return 2;
  }

  final List<String> allowed =
      allowlistFile
          .readAsLinesSync()
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty && !line.startsWith('#'))
          .toList()
        ..sort();

  final List<String> unexpected = <String>[];
  for (final String hit in hits) {
    if (!allowed.contains(hit)) {
      unexpected.add(hit);
    }
  }

  final List<String> stale = <String>[];
  for (final String entry in allowed) {
    if (!hits.contains(entry)) {
      stale.add(entry);
    }
  }

  if (hits.length > allowed.length) {
    stderr.writeln(
      '$patternDescription count increased: ${hits.length} > ${allowed.length} '
      '(ratchet only allows decreases).\n'
      'New hits:\n${unexpected.join('\n')}',
    );
    return 1;
  }

  if (unexpected.isNotEmpty) {
    stderr.writeln(
      '$patternDescription check failed — unlisted hits (${unexpected.length}):\n'
      '${unexpected.join('\n')}\n$fixHint',
    );
    return 1;
  }

  if (stale.isNotEmpty) {
    stderr.writeln(
      '$patternDescription check failed — stale allowlist (${stale.length}):\n'
      '${stale.join('\n')}',
    );
    return 1;
  }

  stdout.writeln(
    '$patternDescription check passed (${allowed.length} allowlisted).',
  );
  return 0;
}

void stampAllowlist({
  required String allowlistPath,
  required List<String> hits,
}) {
  hits.sort();
  File(allowlistPath).writeAsStringSync('${hits.join('\n')}\n');
  stdout.writeln('Wrote ${hits.length} lines to $allowlistPath');
}

bool wantsStampBaseline(List<String> args) => args.contains('--stamp-baseline');

List<String> scanDartRoots({
  required List<String> roots,
  required List<String> skipPathFragments,
  required bool Function(String line) matchesLine,
}) {
  final List<String> hits = <String>[];
  for (final String rootPath in roots) {
    final Directory root = Directory(rootPath);
    if (!root.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String normalized = entity.path.replaceAll(r'\', '/');
      if (skipPathFragments.any(normalized.contains)) {
        continue;
      }
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (matchesLine(lines[i])) {
          hits.add('$normalized:${i + 1}');
        }
      }
    }
  }
  return hits;
}
