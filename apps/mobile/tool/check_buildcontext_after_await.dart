// ignore_for_file: avoid_print

import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

/// Windowed guard: BuildContext use after await without mounted guard (whole app).
int runBuildContextAfterAwaitCheck() {
  return runRatchetingAllowlistCheck(
    patternDescription: 'BuildContext-after-await',
    hits: collectBuildContextAfterAwaitHits(),
    allowlistPath: 'tool/buildcontext_after_await_allowlist.txt',
    fixHint:
        'Add `if (!mounted) return;` after await before using BuildContext',
  );
}

List<String> collectBuildContextAfterAwaitHits() {
  final RegExp awaitRe = RegExp(r'\bawait\b');
  final RegExp mountedGuard = RegExp(r'\b(mounted|context\.mounted)\b');
  final RegExp ctxUse = RegExp(
    r'\b(context\.|Navigator\.of\s*\(\s*context|ScaffoldMessenger\.of\s*\(\s*context|Theme\.of\s*\(\s*context|MediaQuery\.of\s*\(\s*context|Localizations\.of\s*\(\s*context)',
  );
  final List<String> hits = <String>[];
  for (final File file in iterFeatureDartFiles(roots: allFeatureLibRoots())) {
    final String normalized = normalizePath(file.path);
    final List<String> lines = file.readAsLinesSync();
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
            hits.add('$normalized:${j + 1}');
          }
          break;
        }
        if (t == '}' || t.startsWith('}')) break;
      }
    }
  }
  return hits;
}

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: 'tool/buildcontext_after_await_allowlist.txt',
      hits: collectBuildContextAfterAwaitHits(),
    );
    exit(0);
  }
  exit(runBuildContextAfterAwaitCheck());
}
