// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

/// Bans raw `as Map<String, dynamic>` / `as List<dynamic>` in features (use safe_json.dart).
int runNoRawJsonCastCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'Raw JSON cast',
    hits: collectRawJsonCastHits(),
    allowlistPath: 'tool/raw_json_cast_allowlist.txt',
    fixHint:
        'Use safeAsStringKeyedMap / safeAsList / safeJsonDecodeMap from core/serialization/safe_json.dart',
  );
}

List<String> collectRawJsonCastHits() {
  final RegExp badMap = RegExp('as Map<String, dynamic>');
  final RegExp badList = RegExp('as List<dynamic>');
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String ln = lines[i];
      if (ln.trim().startsWith('//')) continue;
      if (badMap.hasMatch(ln) || badList.hasMatch(ln)) {
        hits.add('$normalized:${i + 1}');
      }
    }
  }
  return hits;
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: 'tool/raw_json_cast_allowlist.txt',
      hits: collectRawJsonCastHits(),
    );
    exit(0);
  }
  exit(runNoRawJsonCastCheck());
}
