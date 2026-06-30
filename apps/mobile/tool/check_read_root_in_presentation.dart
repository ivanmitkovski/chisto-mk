// Run from apps/mobile: dart run tool/check_read_root_in_presentation.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const String _allowlistPath = 'tool/read_root_presentation_allowlist.txt';

bool _matchesReadRootLine(String line) =>
    line.contains('readRoot(') || line.contains('tryReadRoot(');

List<String> _scanPresentationReadRoot() => scanFeatureLayerFiles(
  roots: allFeatureLibRoots(),
  includeFile: isPresentationPath,
  matchesLine: _matchesReadRootLine,
);

void main(List<String> args) {
  if (wantsStampBaseline(args)) {
    stampAllowlist(
      allowlistPath: _allowlistPath,
      hits: _scanPresentationReadRoot(),
    );
    exit(0);
  }

  final List<String> hits = _scanPresentationReadRoot();
  hits.sort();

  final File allowlistFile = File(_allowlistPath);
  if (!allowlistFile.existsSync()) {
    stderr.writeln(
      'Missing $_allowlistPath — create it with one path:line per '
      'readRoot()/tryReadRoot() occurrence under presentation/ (sorted).',
    );
    exit(2);
  }

  final List<String> allowed =
      allowlistFile
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
      'readRoot() in presentation count increased: ${hits.length} > ${allowed.length} '
      '(ratchet only allows decreases).\n'
      'New hits:\n${unexpected.join('\n')}',
    );
    exit(1);
  }

  if (unexpected.isNotEmpty) {
    stderr.writeln(
      'readRoot() in presentation check failed — unlisted hits (${unexpected.length}):\n'
      '${unexpected.join('\n')}',
    );
    exit(1);
  }

  if (stale.isNotEmpty) {
    stderr.writeln(
      'readRoot() in presentation check failed — stale allowlist entries '
      '(${stale.length}):\n${stale.join('\n')}',
    );
    exit(1);
  }

  stdout.writeln(
    'readRoot() in presentation check passed (${hits.length} allowlisted).',
  );
}
