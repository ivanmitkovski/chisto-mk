// Run from apps/mobile: dart run tool/check_reports_hardcoded_strings.dart
// Optional: dart run tool/check_reports_hardcoded_strings.dart --stamp-baseline
import 'dart:io';

const String _baselinePath = 'tool/reports_hardcoded_english_baseline.txt';

final RegExp _englishish = RegExp(r'[A-Za-z]{3,}');

bool _allowlistedLine(String line) {
  final String t = line.trimLeft();
  if (t.startsWith('import ') ||
      t.startsWith('export ') ||
      t.startsWith('part ')) {
    return true;
  }
  return false;
}

bool _allowlistedLiteral(String lit) {
  if (lit.isEmpty) return true;
  if (lit.startsWith('package:') ||
      lit.startsWith('dart:') ||
      lit.startsWith('assets/') ||
      lit.startsWith('http://') ||
      lit.startsWith('https://')) {
    return true;
  }
  if (lit.startsWith('image/') || lit == 'application/octet-stream') {
    return true;
  }
  if (lit.startsWith('RegExp(')) return true;
  if (RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(lit)) return true;
  return false;
}

Iterable<String> _literalsInLine(String line) sync* {
  final RegExp sq = RegExp(r"'((?:\\.|[^'\\])*)'");
  final RegExp dq = RegExp(r'"((?:\\.|[^"\\])*)"');
  for (final RegExpMatch m in sq.allMatches(line)) {
    yield m.group(1)!;
  }
  for (final RegExpMatch m in dq.allMatches(line)) {
    yield m.group(1)!;
  }
}

int runHardcodedEnglishCheck({required bool stampBaseline}) {
  final Directory root = Directory('lib/features/reports');
  if (!root.existsSync()) {
    stderr.writeln('Run from apps/mobile');
    return 2;
  }
  final List<String> findings = <String>[];
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final List<String> lines = e.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (_allowlistedLine(line)) continue;
      if (line.trimLeft().startsWith('//')) continue;
      for (final String lit in _literalsInLine(line)) {
        if (_allowlistedLiteral(lit)) continue;
        if (!_englishish.hasMatch(lit)) continue;
        final String rel = e.path.replaceFirst(RegExp(r'^.*?/lib/'), 'lib/');
        findings.add('$rel:${i + 1}:$lit');
      }
    }
  }
  findings.sort();
  final File baselineFile = File(_baselinePath);
  if (stampBaseline) {
    baselineFile.writeAsStringSync('${findings.join('\n')}\n');
    stdout.writeln('Wrote ${findings.length} lines to $_baselinePath');
    return 0;
  }
  final Set<String> baseline = <String>{};
  if (baselineFile.existsSync()) {
    baseline.addAll(
      baselineFile.readAsLinesSync().where((String l) => l.trim().isNotEmpty),
    );
  }
  final List<String> novel = <String>[];
  for (final String f in findings) {
    if (!baseline.contains(f)) novel.add(f);
  }
  if (novel.isNotEmpty) {
    stderr.writeln(
      'Hardcoded English scan failed (new literals):\n${novel.join('\n')}',
    );
    return 1;
  }
  stdout.writeln('OK: hardcoded English baseline.');
  return 0;
}

void main(List<String> args) {
  final bool stamp = args.contains('--stamp-baseline');
  exit(runHardcodedEnglishCheck(stampBaseline: stamp));
}
