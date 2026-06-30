// Usage: dart run tool/check_no_flutter_in_chisto_core.dart
import 'dart:io';

int runNoFlutterInChistoCoreCheck() {
  final RegExp flutterImport = RegExp(r"import\s+'package:flutter/");
  final List<String> hits = <String>[];
  final Directory root = Directory('packages/chisto_core/lib');
  for (final FileSystemEntity e in root.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    final List<String> lines = e.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (flutterImport.hasMatch(lines[i])) {
        hits.add('${e.path}:${i + 1}');
      }
    }
  }
  if (hits.isNotEmpty) {
    stderr.writeln(
      'Flutter import in chisto_core (${hits.length}):\n${hits.join('\n')}',
    );
    return 1;
  }
  stdout.writeln('chisto_core is Flutter-free.');
  return 0;
}

void main() {
  exit(runNoFlutterInChistoCoreCheck());
}
