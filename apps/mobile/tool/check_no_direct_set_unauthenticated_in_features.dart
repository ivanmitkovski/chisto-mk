// ignore_for_file: avoid_print

import 'dart:io';

/// Bans [AuthState.setUnauthenticated] outside core/auth and features/auth.
int runNoDirectSetUnauthenticatedInFeaturesCheck() {
  final Directory root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('Run from apps/mobile');
    return 2;
  }
  const Set<String> allowedPrefixes = <String>{
    'lib/core/auth/',
    'lib/core/bootstrap/',
    'lib/features/auth/',
  };
  final RegExp call = RegExp(r'\.setUnauthenticated\s*\(');
  final List<String> violations = <String>[];
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final String normalized = e.path.replaceAll(r'\', '/');
    if (allowedPrefixes.any(normalized.contains)) continue;
    final List<String> lines = e.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String ln = lines[i];
      if (ln.trim().startsWith('//')) continue;
      if (call.hasMatch(ln)) {
        violations.add('$normalized:${i + 1}: $ln');
      }
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(
      'Direct setUnauthenticated() in feature code (use ApiClient / onAuthRejected):\n'
      '${violations.join('\n')}',
    );
    return 1;
  }
  stdout.writeln('OK: no direct setUnauthenticated() outside auth modules.');
  return 0;
}

void main() {
  exit(runNoDirectSetUnauthenticatedInFeaturesCheck());
}
