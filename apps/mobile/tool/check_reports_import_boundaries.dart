// Usage: dart run tool/check_reports_import_boundaries.dart
// Ensures lib/features/reports does not import other feature verticals directly.
import 'dart:io';

final RegExp _forbidden = RegExp(
  r"import\s+'package:chisto_mobile/features/(events|home)/",
);

Future<void> main() async {
  final Directory root = Directory('lib/features/reports');
  final List<String> hits = <String>[];
  await for (final FileSystemEntity e in root.list(recursive: true, followLinks: false)) {
    if (e is! File || !e.path.endsWith('.dart')) {
      continue;
    }
    final String content = await e.readAsString();
    for (final RegExpMatch m in _forbidden.allMatches(content)) {
      hits.add('${e.path}: ${m.group(0)}');
    }
  }
  if (hits.isNotEmpty) {
    stderr.writeln('Forbidden cross-feature imports in reports:\n${hits.join('\n')}');
    exitCode = 1;
    return;
  }
  stdout.writeln('OK: reports feature has no direct imports from events/home.');
}
