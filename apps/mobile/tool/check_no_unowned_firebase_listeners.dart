// ignore_for_file: avoid_print

import 'dart:io';

import 'feature_roots_guard_util.dart';

/// Fails when FirebaseMessaging listener `.listen` results are not assigned.
int runNoUnownedFirebaseListenersCheck() {
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
  for (final File file in iterFeatureDartFiles(roots: allAppCodeRoots())) {
    final String normalized = normalizePath(file.path);
    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String ln = lines[i];
      if (!bad.hasMatch(ln) && !ln.contains('onTokenRefresh.listen')) {
        continue;
      }
      if (ln.contains('onTokenRefresh.listen') && tokenAssigned.hasMatch(ln)) {
        continue;
      }
      if (bad.hasMatch(ln) && assigned.hasMatch(ln)) {
        continue;
      }
      if (ln.trim().startsWith('//')) {
        continue;
      }
      if (ln.contains('onTokenRefresh.listen') && !tokenAssigned.hasMatch(ln)) {
        violations.add('$normalized:${i + 1}: $ln');
      } else if (bad.hasMatch(ln) && !assigned.hasMatch(ln)) {
        violations.add('$normalized:${i + 1}: $ln');
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
