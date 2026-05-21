// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';

/// Bans raw `as Map<String, dynamic>` / `as List<dynamic>` in features (use safe_json.dart).
int runNoRawJsonCastCheck() {
  final Directory root = Directory('lib/features');
  final RegExp badMap = RegExp(r'as Map<String, dynamic>');
  final RegExp badList = RegExp(r'as List<dynamic>');
  final List<String> hits = <String>[];
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final List<String> lines = e.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String ln = lines[i];
      if (ln.trim().startsWith('//')) continue;
      if (badMap.hasMatch(ln) || badList.hasMatch(ln)) {
        hits.add('${e.path}:${i + 1}');
      }
    }
  }
  return runRatchetingAllowlistCheck(
    patternDescription: 'Raw JSON cast',
    hits: hits,
    allowlistPath: 'tool/raw_json_cast_allowlist.txt',
    fixHint: 'Use safeAsStringKeyedMap / safeAsList / safeJsonDecodeMap from core/serialization/safe_json.dart',
  );
}

void main() {
  exit(runNoRawJsonCastCheck());
}
