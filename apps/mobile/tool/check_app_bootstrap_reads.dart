// Run from apps/mobile: dart run tool/check_app_bootstrap_reads.dart
import 'dart:io';

const String _pattern = 'AppBootstrap.instance';
const String _allowlistPath = 'tool/app_bootstrap_allowlist.txt';

void main() {
  final Directory libRoot = Directory('lib');
  if (!libRoot.existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }

  final List<String> hits = <String>[];
  for (final FileSystemEntity entity in libRoot.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String normalized = entity.path.replaceAll(r'\', '/');
    final List<String> lines = entity.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(_pattern)) {
        hits.add('$normalized:${i + 1}');
      }
    }
  }
  hits.sort();

  final File allowlistFile = File(_allowlistPath);
  if (!allowlistFile.existsSync()) {
    stderr.writeln(
      'Missing $_allowlistPath — create it with one `lib/...:line` per '
      '$_pattern occurrence (sorted).',
    );
    exit(2);
  }

  final List<String> allowed = allowlistFile
      .readAsLinesSync()
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty && !line.startsWith('#'))
      .toList()
    ..sort();

  final List<String> unexpected = <String>[];
  for (final String hit in hits) {
    if (!allowed.contains(hit)) {
      unexpected.add(hit);
    }
  }

  final List<String> stale = <String>[];
  for (final String entry in allowed) {
    if (!hits.contains(entry)) {
      stale.add(entry);
    }
  }

  if (hits.length > allowed.length) {
    stderr.writeln(
      'AppBootstrap.instance count increased: ${hits.length} > ${allowed.length} '
      '(ratchet only allows decreases).\n'
      'New hits:\n${unexpected.join('\n')}',
    );
    exit(1);
  }

  if (unexpected.isNotEmpty) {
    stderr.writeln(
      'AppBootstrap.instance check failed — unlisted hits (${unexpected.length}):\n'
      '${unexpected.join('\n')}',
    );
    exit(1);
  }

  if (stale.isNotEmpty) {
    stderr.writeln(
      'AppBootstrap.instance check failed — stale allowlist entries '
      '(${stale.length}):\n${stale.join('\n')}',
    );
    exit(1);
  }

  stdout.writeln(
    'AppBootstrap.instance check passed (${hits.length} allowlisted).',
  );
}
