// Run from apps/mobile: dart run tool/check_screen_size.dart
import 'dart:io';

const int _hardLineLimit = 600;
const int _warnLineLimit = 400;

/// Screens under this path are checked for composition-only size budgets.
const String _screensPrefix = 'lib/features/';

/// Legacy large screens tracked in docs/beta-followups.md (next decomposition pass).
const Set<String> _legacyLargeScreenAllowlist = <String>{
  // Wave 15 — decomposition backlog (ratchet; do not add entries).
  'lib/features/events/presentation/organizer_checkin/organizer_checkin_screen_state.dart',
};

void main() {
  final Directory libRoot = Directory('lib');
  if (!libRoot.existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }

  final List<String> hardViolations = <String>[];
  final List<String> warnings = <String>[];

  for (final FileSystemEntity entity in libRoot.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String normalized = entity.path.replaceAll(r'\', '/');
    if (!normalized.contains('${_screensPrefix}') ||
        !normalized.contains('/presentation/') ||
        !normalized.contains('/screens/') ||
        !normalized.endsWith('_screen.dart')) {
      continue;
    }

    final int lines = entity.readAsLinesSync().length;
    if (lines > _hardLineLimit) {
      if (_legacyLargeScreenAllowlist.contains(normalized)) {
        warnings.add(
          '$normalized: $lines lines (legacy allowlist — see docs/beta-followups.md)',
        );
        continue;
      }
      hardViolations.add(
        '$normalized: $lines lines (hard limit $_hardLineLimit)',
      );
    } else if (lines > _warnLineLimit) {
      warnings.add('$normalized: $lines lines (warn above $_warnLineLimit)');
    }
  }

  if (warnings.isNotEmpty) {
    stderr.writeln(
      'Screen size warnings (${warnings.length}):\n${warnings.join('\n')}\n',
    );
  }

  if (hardViolations.isNotEmpty) {
    stderr.writeln(
      'Screen size check failed (${hardViolations.length} file(s) > $_hardLineLimit LoC):\n'
      '${hardViolations.join('\n')}',
    );
    exit(1);
  }

  stdout.writeln(
    'Screen size check passed (hard ≤$_hardLineLimit, warn ≤$_warnLineLimit).',
  );
}
