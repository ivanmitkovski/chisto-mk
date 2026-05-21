// ignore_for_file: avoid_print

import 'dart:io';

/// Fails when FirebaseMessaging listener `.listen` results are not assigned.
int runNoUnownedFirebaseListenersCheck() {
  final Directory root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('Run from apps/mobile');
    return 2;
  }
  final RegExp bad = RegExp(
    r'FirebaseMessaging\.(onMessage|onMessageOpenedApp)\.listen\s*\(',
  );
  final RegExp assigned = RegExp(
    r'=\s*FirebaseMessaging\.(onMessage|onMessageOpenedApp)\.listen\s*\(',
  );
  final RegExp tokenAssigned = RegExp(
    r'=\s*FirebaseMessaging\.instance\.onTokenRefresh\.listen\s*\(',
  );
  final List<String> violations = <String>[];
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final List<String> lines = e.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String ln = lines[i];
      if (!bad.hasMatch(ln) && !ln.contains('onTokenRefresh.listen')) continue;
      if (ln.contains('onTokenRefresh.listen') && tokenAssigned.hasMatch(ln)) {
        continue;
      }
      if (bad.hasMatch(ln) && assigned.hasMatch(ln)) {
        continue;
      }
      if (ln.trim().startsWith('//')) continue;
      if (ln.contains('onTokenRefresh.listen') && !tokenAssigned.hasMatch(ln)) {
        violations.add('${e.path}:${i + 1}: $ln');
      } else if (bad.hasMatch(ln) && !assigned.hasMatch(ln)) {
        violations.add('${e.path}:${i + 1}: $ln');
      }
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(
      'Unowned FirebaseMessaging listeners:\n${violations.join('\n')}',
    );
    return 1;
  }
  stdout.writeln('OK: FirebaseMessaging listeners are assigned.');
  return 0;
}

void main() {
  exit(runNoUnownedFirebaseListenersCheck());
}
