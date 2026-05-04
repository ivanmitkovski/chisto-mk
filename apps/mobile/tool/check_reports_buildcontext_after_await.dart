// ignore_for_file: avoid_print

import 'dart:io';

/// Windowed guard: after `await`, the next few non-comment lines must not use
/// [BuildContext] helpers without an intervening `mounted` / `context.mounted` guard.
int runBuildContextAfterAwaitCheck() {
  final Directory root = Directory('lib/features/reports');
  if (!root.existsSync()) {
    stderr.writeln('Run from apps/mobile');
    return 2;
  }
  final RegExp awaitRe = RegExp(r'\bawait\b');
  final RegExp mountedGuard = RegExp(
    r'\b(mounted|context\.mounted)\b',
  );
  final RegExp ctxUse = RegExp(
    r'\b(context\.|Navigator\.of\s*\(\s*context|ScaffoldMessenger\.of\s*\(\s*context|Theme\.of\s*\(\s*context|MediaQuery\.of\s*\(\s*context|Localizations\.of\s*\(\s*context)',
  );
  final List<String> violations = <String>[];
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
            violations.add('${e.path}:${j + 1}: $ln');
          }
          break;
        }
        if (t == '}' || t.startsWith('}')) {
          break;
        }
      }
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(
      'BuildContext-after-await:\n${violations.join('\n')}',
    );
    return 1;
  }
  stdout.writeln('OK: no BuildContext-after-await in reports.');
  return 0;
}

void main() {
  exit(runBuildContextAfterAwaitCheck());
}
