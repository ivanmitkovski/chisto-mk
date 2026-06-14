import 'dart:io';

const Set<String> kHardcodedPhaseKeys = <String>{
  'loading',
  'error',
  'content',
  'refresh_failed',
};

final RegExp _englishish = RegExp('[A-Za-z]{3,}');
final RegExp _internalIdentifier = RegExp(r'^[a-z][a-zA-Z0-9_.]*$');
final RegExp _keyedIdentifier = RegExp(r'^[a-z0-9][a-z0-9_-]*$');
final RegExp _routeParam = RegExp(r'^:[a-zA-Z][a-zA-Z0-9]*$');
final RegExp _logTagPrefix = RegExp('^[a-z_]+:');

bool isGeneratedDartFile(String path) => path.endsWith('.g.dart');

bool allowlistedHardcodedLine(String line) {
  final String t = line.trimLeft();
  if (t.startsWith('import ') ||
      t.startsWith('export ') ||
      t.startsWith('part ')) {
    return true;
  }
  return false;
}

bool allowlistedHardcodedLiteral(String lit, {String line = ''}) {
  if (lit.isEmpty) return true;
  if (line.contains('assert(') ||
      line.contains('AppLog.') ||
      line.contains('debugPrint(') ||
      line.contains('Sentry.capture')) {
    return true;
  }
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
  if (lit.startsWith('l10n.') || lit.contains('.l10n.')) return true;
  if (kHardcodedPhaseKeys.contains(lit)) return true;
  if (lit.contains(r'$')) return true;
  if (_internalIdentifier.hasMatch(lit)) return true;
  if (_keyedIdentifier.hasMatch(lit)) return true;
  if (_routeParam.hasMatch(lit)) return true;
  if (lit.startsWith('&')) return true;
  if (lit == 'LateInitializationError:') return true;
  if (_logTagPrefix.hasMatch(lit)) return true;
  if (lit.startsWith('/') || lit.startsWith('branch-')) return true;
  if (lit.startsWith('file://')) return true;
  if (RegExp('^[a-z]+/').hasMatch(lit)) return true;
  return false;
}

Iterable<String> hardcodedLiteralsInLine(String line) sync* {
  final RegExp sq = RegExp(r"'((?:\\.|[^'\\])*)'");
  final RegExp dq = RegExp(r'"((?:\\.|[^"\\])*)"');
  for (final RegExpMatch m in sq.allMatches(line)) {
    yield m.group(1)!;
  }
  for (final RegExpMatch m in dq.allMatches(line)) {
    yield m.group(1)!;
  }
}

bool lineHasEnglishHardcodedLiteral(String line) {
  if (allowlistedHardcodedLine(line)) return false;
  if (line.trimLeft().startsWith('//')) return false;
  for (final String lit in hardcodedLiteralsInLine(line)) {
    if (allowlistedHardcodedLiteral(lit, line: line)) continue;
    if (_englishish.hasMatch(lit)) return true;
  }
  return false;
}

bool _lineIsAssertMessage(List<String> lines, int index) {
  for (int j = index; j >= 0 && j > index - 3; j--) {
    if (lines[j].contains('assert(')) return true;
  }
  return false;
}

bool _lineIsLogContinuation(List<String> lines, int index) {
  for (int j = index; j >= 0 && j > index - 6; j--) {
    if (lines[j].contains('AppLog.') ||
        lines[j].contains('debugPrint(') ||
        lines[j].contains('Sentry.capture')) {
      return true;
    }
  }
  return false;
}

List<String> scanHardcodedEnglish({
  required Iterable<String> rootPaths,
  bool skipDataLayer = false,
}) {
  final List<String> findings = <String>[];
  for (final String rootPath in rootPaths) {
    final Directory root = Directory(rootPath);
    if (!root.existsSync()) continue;
    for (final FileSystemEntity e in root.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      if (isGeneratedDartFile(e.path)) continue;
      if (skipDataLayer && e.path.contains('/lib/src/data/')) continue;
      final List<String> lines = e.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (allowlistedHardcodedLine(line)) continue;
        if (line.trimLeft().startsWith('//')) continue;
        final bool assertMessage = _lineIsAssertMessage(lines, i);
        final bool logContinuation = _lineIsLogContinuation(lines, i);
        for (final String lit in hardcodedLiteralsInLine(line)) {
          if (allowlistedHardcodedLiteral(
            lit,
            line: assertMessage
                ? 'assert($line'
                : logContinuation
                ? 'AppLog.$line'
                : line,
          )) {
            continue;
          }
          if (!_englishish.hasMatch(lit)) continue;
          final String rel = e.path.replaceFirst(RegExp('^.*?/lib/'), 'lib/');
          findings.add('$rel:${i + 1}:$lit');
        }
      }
    }
  }
  findings.sort();
  return findings;
}

int runHardcodedEnglishBaselineCheck({
  required List<String> rootPaths,
  required String baselinePath,
  required bool stampBaseline,
  bool skipDataLayer = false,
  String okMessage = 'OK: hardcoded English baseline.',
}) {
  final List<String> findings = scanHardcodedEnglish(
    rootPaths: rootPaths,
    skipDataLayer: skipDataLayer,
  );
  final File baselineFile = File(baselinePath);

  if (stampBaseline) {
    baselineFile.writeAsStringSync('${findings.join('\n')}\n');
    stdout.writeln('Wrote ${findings.length} lines to $baselinePath');
    return 0;
  }

  final Set<String> baseline = <String>{};
  if (baselineFile.existsSync()) {
    baseline.addAll(
      baselineFile.readAsLinesSync().where((String l) => l.trim().isNotEmpty),
    );
  } else {
    stderr.writeln(
      'Missing $baselinePath — run with --stamp-baseline first.\n'
      'Current findings: ${findings.length}',
    );
    return 2;
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

  stdout.writeln(okMessage);
  return 0;
}
