// Merge multiple lcov.info fragments into one file.
// Usage: dart run tool/merge_lcov.dart part1.info part2.info out.info
import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/merge_lcov.dart <inputs...> <output>');
    exit(2);
  }

  final String outputPath = args.last;
  final List<String> inputPaths = args.sublist(0, args.length - 1);
  final Map<String, Map<int, int>> merged = <String, Map<int, int>>{};

  for (final String path in inputPaths) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    _parseInto(file.readAsStringSync(), merged);
  }

  final StringBuffer buffer = StringBuffer();
  final List<String> paths = merged.keys.toList()..sort();
  for (final String path in paths) {
    buffer.writeln('SF:$path');
    final List<int> lines = merged[path]!.keys.toList()..sort();
    for (final int line in lines) {
      buffer.writeln('DA:$line,${merged[path]![line]}');
    }
    buffer.writeln('end_of_record');
  }

  File(outputPath).writeAsStringSync(buffer.toString());
  stdout.writeln(
    'Merged ${inputPaths.length} fragments into $outputPath '
    '(${paths.length} files).',
  );
}

void _parseInto(String content, Map<String, Map<int, int>> merged) {
  String? currentPath;
  Map<int, int>? currentHits;

  for (final String rawLine in content.split('\n')) {
    final String line = rawLine.trim();
    if (line.startsWith('SF:')) {
      currentPath = line.substring(3).replaceAll(r'\', '/');
      currentHits = merged.putIfAbsent(currentPath, () => <int, int>{});
      continue;
    }
    if (line.startsWith('DA:') && currentHits != null) {
      final List<String> parts = line.substring(3).split(',');
      if (parts.length < 2) continue;
      final int? lineNumber = int.tryParse(parts[0]);
      final int? executions = int.tryParse(parts[1]);
      if (lineNumber == null || executions == null) continue;
      final int? existing = currentHits[lineNumber];
      if (existing == null || executions > existing) {
        currentHits[lineNumber] = executions;
      }
      continue;
    }
    if (line == 'end_of_record') {
      currentPath = null;
      currentHits = null;
    }
  }
}
