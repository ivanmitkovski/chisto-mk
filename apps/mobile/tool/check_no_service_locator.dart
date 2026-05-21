// Run from apps/mobile: dart run tool/check_no_service_locator.dart
import 'dart:io';

const List<String> _banned = <String>[
  'ServiceLocator',
  'service_locator.dart',
];

void main() {
  final Directory libRoot = Directory('lib');
  if (!libRoot.existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }

  final List<String> violations = <String>[];

  for (final FileSystemEntity entity in libRoot.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String normalized = entity.path.replaceAll(r'\', '/');
    if (normalized.contains('core/bootstrap/app_bootstrap.dart')) {
      continue;
    }

    final List<String> lines = entity.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      for (final String pattern in _banned) {
        if (line.contains(pattern)) {
          violations.add('$normalized:${i + 1}: banned `$pattern`');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'ServiceLocator ban failed (${violations.length}):\n${violations.join('\n')}',
    );
    exit(1);
  }

  stdout.writeln('No ServiceLocator references in lib/.');
}
