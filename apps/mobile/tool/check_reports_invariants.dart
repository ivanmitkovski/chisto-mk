// Run from apps/mobile: dart run tool/check_reports_invariants.dart
import 'dart:convert';
import 'dart:io';

import 'check_no_hex_in_reports.dart' as hex_check;
import 'check_reports_buildcontext_after_await.dart' as ctx_check;
import 'check_reports_hardcoded_strings.dart' as hardcoded_check;
import 'check_reports_widget_size.dart' as widget_size_check;

Set<String> _arbMessageKeys(String path) {
  final File f = File(path);
  if (!f.existsSync()) {
    stderr.writeln('ARB not found: $path');
    return <String>{};
  }
  final Object? decoded = json.decode(f.readAsStringSync());
  if (decoded is! Map) {
    return <String>{};
  }
  return decoded.keys
      .map((Object? k) => k.toString())
      .where((String k) => !k.startsWith('@'))
      .toSet();
}

int _runArbParityCheck() {
  final Set<String> en = _arbMessageKeys('lib/l10n/app_en.arb');
  final Set<String> mk = _arbMessageKeys('lib/l10n/app_mk.arb');
  final Set<String> sq = _arbMessageKeys('lib/l10n/app_sq.arb');
  final List<String> violations = <String>[];
  for (final String k in en) {
    if (!mk.contains(k)) {
      violations.add('Missing in app_mk.arb: $k');
    }
    if (!sq.contains(k)) {
      violations.add('Missing in app_sq.arb: $k');
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln('ARB parity failed:\n${violations.join('\n')}');
    return 1;
  }
  return 0;
}

void main() {
  final int hexCode = hex_check.runNoHexInReportsCheck();
  if (hexCode != 0) {
    exit(hexCode);
  }

  final int arbCode = _runArbParityCheck();
  if (arbCode != 0) {
    exit(arbCode);
  }

  final Directory root = Directory('lib/features/reports');
  if (!root.existsSync()) {
    stderr.writeln('Directory ${root.path} not found (run from apps/mobile).');
    exit(2);
  }

  final List<String> violations = <String>[];
  const String allowedPrecachePath = 'report_image_prefetch_coordinator.dart';

  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    if (entity.path.contains(allowedPrecachePath)) {
      continue;
    }
    final List<String> lines = entity.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (line.contains('precacheImage(')) {
        violations.add('precacheImage: ${entity.path}:${i + 1}');
      }
      if (line.contains('Connectivity()')) {
        violations.add('Connectivity(): ${entity.path}:${i + 1}');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Reports invariants failed:\n'
      '${violations.join('\n')}\n'
      'Use ReportImagePrefetchCoordinator for precacheImage; use ConnectivityGate for connectivity.',
    );
    exit(1);
  }

  final int ctxCode = ctx_check.runBuildContextAfterAwaitCheck();
  if (ctxCode != 0) {
    exit(ctxCode);
  }

  final int hardCode = hardcoded_check.runHardcodedEnglishCheck(stampBaseline: false);
  if (hardCode != 0) {
    exit(hardCode);
  }

  final int ws = widget_size_check.runWidgetSizeCheck();
  if (ws != 0) {
    exit(ws);
  }

  stdout.writeln(
    'OK: reports invariants (hex + ARB + precache + connectivity + ctx-after-await + hardcoded + widget size).',
  );
}
