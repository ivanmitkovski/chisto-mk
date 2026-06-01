// Run from apps/mobile: dart run tool/check_app_bootstrap_reads.dart [--stamp-baseline]
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const String _pattern = 'AppBootstrap.instance';
const String _allowlistPath = 'tool/app_bootstrap_allowlist.txt';

List<String> collectAppBootstrapHits() {
  final List<String> hits = <String>[];
  final List<String> roots = <String>[
    'lib',
    ...discoverFeaturePackageLibRoots(),
  ];
  for (final String rootPath in roots) {
    for (final File file in iterFeatureDartFiles(roots: <String>[rootPath])) {
      final String normalized = normalizePath(file.path);
      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(_pattern)) {
          hits.add('$normalized:${i + 1}');
        }
      }
    }
  }
  return hits;
}

void main(List<String> args) {
  final List<String> hits = collectAppBootstrapHits()..sort();

  if (wantsStampBaseline(args)) {
    stampAllowlist(allowlistPath: _allowlistPath, hits: hits);
    exit(0);
  }

  final File allowlistFile = File(_allowlistPath);
  if (!allowlistFile.existsSync()) {
    stderr.writeln(
      'Missing $_allowlistPath — run with --stamp-baseline first.',
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
