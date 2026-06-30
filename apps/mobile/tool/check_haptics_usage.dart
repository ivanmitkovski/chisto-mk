// Run from apps/mobile: dart run tool/check_haptics_usage.dart
import 'dart:io';

import 'feature_roots_guard_util.dart';

const String _allowedFileSuffix = 'shared/utils/app_haptics.dart';
const String _capAllowlistPath = 'tool/haptics_cap_allowlist.txt';

/// Raw Flutter haptics and legacy [AppHaptics] API names — use the 6-method
/// surface in app_haptics.dart instead.
const List<String> _bannedPatterns = <String>[
  'HapticFeedback.',
  'AppHaptics.softTransition',
  'AppHaptics.boundaryReached',
  'AppHaptics.boundaryLimitPulse',
  'AppHaptics.sheetDismiss',
  'AppHaptics.mapLongPress',
  'AppHaptics.gpsFound',
  'AppHaptics.gpsFailed',
  'AppHaptics.strong',
  'AppHaptics.settle',
  'AppHaptics.pinSelect',
  'AppHaptics.pinDeselect',
  'AppHaptics.clusterExpand',
  'AppHaptics.reenteredBounds',
  'AppHaptics.locationConfirmed',
  'AppHaptics.locationRejected',
  'EventChatHaptics.',
];

const String _appHapticsUsage = 'AppHaptics.';

Map<String, int> _loadCapAllowlist() {
  final File file = File(_capAllowlistPath);
  if (!file.existsSync()) {
    return <String, int>{};
  }
  final Map<String, int> caps = <String, int>{};
  for (final String raw in file.readAsLinesSync()) {
    final String line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final int colon = line.lastIndexOf(':');
    if (colon <= 0) {
      stderr.writeln('Invalid cap allowlist line: $line');
      exit(2);
    }
    final String path = line.substring(0, colon);
    final int? cap = int.tryParse(line.substring(colon + 1));
    if (cap == null) {
      stderr.writeln('Invalid cap allowlist line: $line');
      exit(2);
    }
    caps[path] = cap;
  }
  return caps;
}

void main() {
  final Map<String, int> capAllowlist = _loadCapAllowlist();
  final Map<String, int> usageCounts = <String, int>{};
  final List<String> violations = <String>[];

  for (final File file in iterFeatureDartFiles(roots: allAppCodeRoots())) {
    final String normalized = normalizePath(file.path);
    if (normalized.endsWith(_allowedFileSuffix)) {
      continue;
    }

    final List<String> lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      for (final String pattern in _bannedPatterns) {
        if (line.contains(pattern)) {
          violations.add('$normalized:${i + 1}: banned `$pattern`');
        }
      }
      if (line.contains(_appHapticsUsage)) {
        usageCounts[normalized] = (usageCounts[normalized] ?? 0) + 1;
      }
    }
  }

  for (final MapEntry<String, int> entry in usageCounts.entries) {
    final int? cap = capAllowlist[entry.key];
    if (cap != null && entry.value > cap) {
      violations.add(
        '${entry.key}: AppHaptics usage ${entry.value} exceeds cap $cap',
      );
    }
  }

  for (final String path in capAllowlist.keys) {
    if (!usageCounts.containsKey(path)) {
      violations.add('$path: stale haptics cap allowlist entry (file unused)');
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Haptics policy check failed (${violations.length} violation(s)):\n'
      '${violations.join('\n')}',
    );
    exit(1);
  }

  stdout.writeln('Haptics policy check passed.');
}
