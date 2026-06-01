/// Shared helpers for parsing and merging lcov.info files.
library;

import 'dart:io';

/// Paths excluded from coverage accounting (generated or non-product code).
bool shouldExcludeCoveragePath(String path) {
  final String normalized = path.replaceAll('\\', '/');
  if (normalized.contains('/.dart_tool/')) return true;
  if (normalized.contains('/generated/')) return true;
  if (normalized.endsWith('.g.dart')) return true;
  if (normalized.endsWith('.freezed.dart')) return true;
  if (normalized.contains('app_localizations')) return true;
  if (normalized.endsWith('firebase_options.dart')) return true;
  if (normalized.contains('/test/')) return true;
  if (normalized.contains('/integration_test/')) return true;
  return false;
}

String? coverageLayerForPath(String path) {
  final String normalized = path.replaceAll('\\', '/');
  if (normalized.contains('/application/')) return 'application';
  if (normalized.contains('/data/')) return 'data';
  if (normalized.contains('/domain/')) return 'domain';
  if (normalized.contains('/presentation/')) return 'presentation';
  return 'other';
}

bool isLogicLayer(String? layer) =>
    layer == 'application' || layer == 'data' || layer == 'domain';

class LcovFileCoverage {
  const LcovFileCoverage({
    required this.path,
    required this.hit,
    required this.total,
  });

  final String path;
  final int hit;
  final int total;

  double get percent => total == 0 ? 100.0 : (hit / total) * 100.0;
}

class LcovSummary {
  const LcovSummary({
    required this.files,
    required this.hit,
    required this.total,
  });

  final List<LcovFileCoverage> files;
  final int hit;
  final int total;

  double get percent => total == 0 ? 100.0 : (hit / total) * 100.0;
}

/// Parses one or more lcov files and returns merged per-file line coverage.
LcovSummary parseLcovFiles(Iterable<String> paths) {
  final Map<String, Map<int, int>> merged = <String, Map<int, int>>{};

  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    _parseLcovContent(file.readAsStringSync(), merged);
  }

  final List<LcovFileCoverage> files = <LcovFileCoverage>[];
  var hit = 0;
  var total = 0;

  for (final MapEntry<String, Map<int, int>> entry in merged.entries) {
    if (shouldExcludeCoveragePath(entry.key)) continue;
    var fileHit = 0;
    var fileTotal = 0;
    for (final int executions in entry.value.values) {
      fileTotal++;
      if (executions > 0) fileHit++;
    }
    if (fileTotal == 0) continue;
    files.add(
      LcovFileCoverage(path: entry.key, hit: fileHit, total: fileTotal),
    );
    hit += fileHit;
    total += fileTotal;
  }

  files.sort(
    (LcovFileCoverage a, LcovFileCoverage b) => a.path.compareTo(b.path),
  );
  return LcovSummary(files: files, hit: hit, total: total);
}

void _parseLcovContent(String content, Map<String, Map<int, int>> merged) {
  String? currentPath;
  Map<int, int>? currentHits;

  for (final String rawLine in content.split('\n')) {
    final String line = rawLine.trim();
    if (line.startsWith('SF:')) {
      currentPath = _normalizeLcovPath(line.substring(3));
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

String _normalizeLcovPath(String path) {
  var normalized = path.replaceAll('\\', '/');
  const String marker = '/apps/mobile/';
  final int markerIndex = normalized.indexOf(marker);
  if (markerIndex >= 0) {
    normalized = normalized.substring(markerIndex + marker.length);
  }
  return normalized;
}

String? packageNameForPath(String path) {
  final String normalized = path.replaceAll('\\', '/');
  if (normalized.startsWith('packages/')) {
    final List<String> parts = normalized.split('/');
    if (parts.length >= 2) return parts[1];
  }
  if (normalized.startsWith('lib/')) return 'app';
  return null;
}

Map<String, LcovSummary> summarizeByPackage(LcovSummary summary) {
  final Map<String, List<LcovFileCoverage>> grouped =
      <String, List<LcovFileCoverage>>{};
  for (final LcovFileCoverage file in summary.files) {
    final String package = packageNameForPath(file.path) ?? 'other';
    grouped.putIfAbsent(package, () => <LcovFileCoverage>[]).add(file);
  }

  final Map<String, LcovSummary> byPackage = <String, LcovSummary>{};
  for (final MapEntry<String, List<LcovFileCoverage>> entry
      in grouped.entries) {
    var hit = 0;
    var total = 0;
    for (final LcovFileCoverage file in entry.value) {
      hit += file.hit;
      total += file.total;
    }
    byPackage[entry.key] = LcovSummary(
      files: entry.value,
      hit: hit,
      total: total,
    );
  }
  return byPackage;
}

LcovSummary summarizeLogicLayers(LcovSummary summary) {
  final List<LcovFileCoverage> files = <LcovFileCoverage>[];
  var hit = 0;
  var total = 0;
  for (final LcovFileCoverage file in summary.files) {
    if (!isLogicLayer(coverageLayerForPath(file.path))) continue;
    files.add(file);
    hit += file.hit;
    total += file.total;
  }
  return LcovSummary(files: files, hit: hit, total: total);
}
