// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';

/// Bans readAsBytes/readAsBytesSync in upload/multipart paths (ratchet).
int runNoReadAsBytesInUploadPathsCheck() {
  final RegExp pattern = RegExp(r'readAsBytes(Sync)?\s*\(');
  final List<String> roots = <String>[
    'lib/features/reports/data',
    'lib/features/events/presentation/event_chat',
    'lib/features/profile/presentation/avatar',
  ];
  final List<String> hits = <String>[];
  for (final String rootPath in roots) {
    final Directory root = Directory(rootPath);
    if (!root.existsSync()) continue;
    for (final FileSystemEntity e in root.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final List<String> lines = e.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          hits.add('${e.path}:${i + 1}');
        }
      }
    }
  }
  return runRatchetingAllowlistCheck(
    patternDescription: 'readAsBytes in upload paths',
    hits: hits,
    allowlistPath: 'tool/readasbytes_upload_allowlist.txt',
    fixHint: 'Prefer streaming multipart or size-capped reads',
  );
}

void main() {
  exit(runNoReadAsBytesInUploadPathsCheck());
}
