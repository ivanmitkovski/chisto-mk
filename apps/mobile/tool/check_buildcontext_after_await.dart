// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';

/// Windowed guard: BuildContext use after await without mounted guard (whole app).
int runBuildContextAfterAwaitCheck() {
  final Directory root = Directory('lib/features');
  final RegExp awaitRe = RegExp(r'\bawait\b');
  final RegExp mountedGuard = RegExp(r'\b(mounted|context\.mounted)\b');
  final RegExp ctxUse = RegExp(
    r'\b(context\.|Navigator\.of\s*\(\s*context|ScaffoldMessenger\.of\s*\(\s*context|Theme\.of\s*\(\s*context|MediaQuery\.of\s*\(\s*context|Localizations\.of\s*\(\s*context)',
  );
  final List<String> hits = <String>[];
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final List<String> lines = e.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (!awaitRe.hasMatch(lines[i])) continue;
      bool sawGuard = false;
      for (int j = i + 1; j < lines.length && j <= i + 12; j++) {
        final String ln = lines[j];
        final String t = ln.trim();
        if (t.isEmpty || t.startsWith('//')) continue;
        if (mountedGuard.hasMatch(ln)) {
          sawGuard = true;
          continue;
        }
        if (ctxUse.hasMatch(ln)) {
          if (!sawGuard) {
            hits.add('${e.path}:${j + 1}');
          }
          break;
        }
        if (t == '}' || t.startsWith('}')) break;
      }
    }
  }
  return runRatchetingAllowlistCheck(
    patternDescription: 'BuildContext-after-await',
    hits: hits,
    allowlistPath: 'tool/buildcontext_after_await_allowlist.txt',
    fixHint: 'Add `if (!mounted) return;` or use mountedThen() from core/widgets/mounted_then.dart',
  );
}

void main() {
  exit(runBuildContextAfterAwaitCheck());
}
