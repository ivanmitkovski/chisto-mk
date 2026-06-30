// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

/// Bans readAsBytes/readAsBytesSync in upload/multipart paths (ratchet).
int runNoReadAsBytesInUploadPathsCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'readAsBytes in upload paths',
    hits: collectReadAsBytesUploadHits(),
    allowlistPath: 'tool/readasbytes_upload_allowlist.txt',
    fixHint:
        'Use streaming upload helpers; avoid loading whole files into memory.',
  );
}

List<String> collectReadAsBytesUploadHits() {
  final RegExp pattern = RegExp(r'readAsBytes(Sync)?\s*\(');
  final List<String> roots = <String>[
    '$reportsPackageRoot/src/data',
    'packages/feature_events/lib/src/presentation/event_chat',
    'packages/feature_profile/lib/src/presentation/avatar',
  ];
  final List<String> hits = <String>[];
  for (final String rootPath in roots) {
    final Directory root = Directory(rootPath);
    if (!root.existsSync()) continue;
    for (final FileSystemEntity e in root.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String normalized = normalizePath(e.path);
      final List<String> lines = e.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          hits.add('$normalized:${i + 1}');
        }
      }
    }
  }
  return hits;
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: 'tool/readasbytes_upload_allowlist.txt',
      hits: collectReadAsBytesUploadHits(),
    );
    exit(0);
  }
  exit(runNoReadAsBytesInUploadPathsCheck());
}
