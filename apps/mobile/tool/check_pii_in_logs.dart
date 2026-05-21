// ignore_for_file: avoid_print
import 'dart:io';

/// Fails if AppLog.warn/error messages embed obvious PII patterns.
void main() {
  final RegExp pii = RegExp(
    r"AppLog\.(warn|error)\([^)]*(@|\+\d{6,}|Bearer\s|accessToken|refreshToken|password)",
    caseSensitive: false,
  );
  final Directory lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run from apps/mobile');
    exit(1);
  }
  final List<String> hits = <String>[];
  for (final FileSystemEntity e in lib.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final String content = e.readAsStringSync();
    for (final RegExpMatch m in pii.allMatches(content)) {
      hits.add('${e.path}: ${m.group(0)}');
    }
  }
  if (hits.isNotEmpty) {
    stderr.writeln('check_pii_in_logs: possible PII in log messages:');
    for (final String h in hits) {
      stderr.writeln('  $h');
    }
    exit(1);
  }
  print('check_pii_in_logs: OK');
}
