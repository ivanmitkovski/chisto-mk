// Run from apps/mobile:
//   melos run coverage:app && dart run tool/check_coverage.dart
// Optional:
//   dart run tool/check_coverage.dart --print-summary
//   dart run tool/check_coverage.dart --min-percent 49
import 'dart:io';

import 'lcov_util.dart';

const String _defaultLcovPath = 'coverage/lcov.info';
const String _globalThresholdPath = 'tool/coverage_threshold.txt';
const String _logicThresholdPath = 'tool/coverage_logic_threshold.txt';

void main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('Run from apps/mobile');
    exit(2);
  }

  final bool printSummary = args.contains('--print-summary');
  final double globalMin = _readThreshold(
    args,
    flag: '--min-percent',
    fallbackPath: _globalThresholdPath,
    defaultValue: 49,
  );
  final double logicMin = _readThreshold(
    args,
    flag: '--min-logic-percent',
    fallbackPath: _logicThresholdPath,
    defaultValue: 75,
  );

  final File lcovFile = File(_defaultLcovPath);
  if (!lcovFile.existsSync()) {
    stderr.writeln(
      'Missing $_defaultLcovPath — run `melos run coverage:app` first.',
    );
    exit(2);
  }

  final LcovSummary summary = parseLcovFiles(<String>[_defaultLcovPath]);
  final LcovSummary logic = summarizeLogicLayers(summary);
  final Map<String, LcovSummary> byPackage = summarizeByPackage(summary);

  if (printSummary) {
    stdout.writeln(
      'Global line coverage: ${summary.percent.toStringAsFixed(2)}% '
      '(${summary.hit}/${summary.total})',
    );
    stdout.writeln(
      'Logic layers (data/domain/application): '
      '${logic.percent.toStringAsFixed(2)}% (${logic.hit}/${logic.total})',
    );
    final List<String> packages = byPackage.keys.toList()..sort();
    for (final String package in packages) {
      final LcovSummary pkg = byPackage[package]!;
      stdout.writeln(
        '  $package: ${pkg.percent.toStringAsFixed(2)}% '
        '(${pkg.hit}/${pkg.total})',
      );
    }
  }

  var failed = false;

  if (summary.percent + 1e-9 < globalMin) {
    failed = true;
    stderr.writeln(
      'Global coverage gate failed: ${summary.percent.toStringAsFixed(2)}% '
      '< ${globalMin.toStringAsFixed(2)}% '
      '(${summary.hit}/${summary.total} lines)',
    );
    _printLowestPackages(byPackage, limit: 8);
  }

  if (logic.percent + 1e-9 < logicMin) {
    failed = true;
    stderr.writeln(
      'Logic-layer coverage gate failed: ${logic.percent.toStringAsFixed(2)}% '
      '< ${logicMin.toStringAsFixed(2)}% '
      '(${logic.hit}/${logic.total} lines in data/domain/application)',
    );
  }

  if (failed) {
    exit(1);
  }

  stdout.writeln(
    'Coverage gates passed: global ${summary.percent.toStringAsFixed(2)}% '
    '>= ${globalMin.toStringAsFixed(2)}%, logic '
    '${logic.percent.toStringAsFixed(2)}% >= ${logicMin.toStringAsFixed(2)}%',
  );
}

double _readThreshold(
  List<String> args, {
  required String flag,
  required String fallbackPath,
  required double defaultValue,
}) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == flag && i + 1 < args.length) {
      final double? value = double.tryParse(args[i + 1]);
      if (value == null) {
        stderr.writeln('Invalid $flag value: ${args[i + 1]}');
        exit(2);
      }
      return value;
    }
  }

  final File thresholdFile = File(fallbackPath);
  if (thresholdFile.existsSync()) {
    for (final String line in thresholdFile.readAsLinesSync()) {
      final String trimmed = line.split('#').first.trim();
      if (trimmed.isEmpty) continue;
      final double? value = double.tryParse(trimmed);
      if (value != null) return value;
    }
  }

  return defaultValue;
}

void _printLowestPackages(
  Map<String, LcovSummary> byPackage, {
  required int limit,
}) {
  final List<MapEntry<String, LcovSummary>> sorted = byPackage.entries.toList()
    ..sort(
      (MapEntry<String, LcovSummary> a, MapEntry<String, LcovSummary> b) =>
          a.value.percent.compareTo(b.value.percent),
    );
  stderr.writeln('Lowest packages:');
  for (final MapEntry<String, LcovSummary> entry in sorted.take(limit)) {
    stderr.writeln(
      '  ${entry.key}: ${entry.value.percent.toStringAsFixed(2)}% '
      '(${entry.value.hit}/${entry.value.total})',
    );
  }
}
