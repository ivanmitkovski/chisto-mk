// Run from apps/mobile: dart run tool/check_no_em_dash_in_arb.dart
import 'dart:convert';
import 'dart:io';

import 'feature_roots_guard_util.dart';

const String _emDash = '\u2014';

/// Placeholder keys that intentionally use a single em dash as empty value.
const Set<String> _allowedEmDashKeys = <String>{
  'profileGeneralEmptyValue',
  'commonNotAvailable',
  'locationPickerAddressPlaceholder',
};

void main() {
  final Directory arbDir = Directory(l10nRoot);
  if (!arbDir.existsSync()) {
    stderr.writeln('$l10nRoot not found (run from apps/mobile).');
    exit(2);
  }

  final List<String> violations = <String>[];
  for (final FileSystemEntity entity in arbDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.arb')) {
      continue;
    }
    final Map<String, dynamic> json =
        jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>;
    for (final MapEntry<String, dynamic> entry in json.entries) {
      final String key = entry.key;
      if (key.startsWith('@') || key.startsWith('@@')) {
        continue;
      }
      if (_allowedEmDashKeys.contains(key)) {
        continue;
      }
      final dynamic value = entry.value;
      if (value is String && value.contains(_emDash)) {
        violations.add('${entity.path}:$key');
      }
    }
  }

  violations.sort();
  if (violations.isNotEmpty) {
    stderr.writeln(
      'Prose em dash (—) found in ARB values (${violations.length}):\n'
      '${violations.join('\n')}\n'
      'Rewrite to commas/periods, or add to _allowedEmDashKeys only for placeholders.',
    );
    exit(1);
  }
  stdout.writeln('ARB em-dash check passed (placeholders only).');
}
