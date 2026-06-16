// Run from apps/mobile: dart run tool/check_no_raw_error_message_in_ui.dart
import 'dart:io';

import 'design_system_guard_util.dart';
import 'feature_roots_guard_util.dart';

const List<String> _skipPathFragments = <String>[
  'test/',
  'event_chat_stream_coordinator.dart',
  'event_chat_title_bootstrap_coordinator.dart',
  'event_chat_screen.dart',
  'chat_message_bubble.dart',
  'chat_pinned_messages_sheet.dart',
  'new_report_submit_ui_flow.dart',
];

bool _matchesLine(String line) {
  final String trimmed = line.trim();
  if (trimmed.startsWith('//')) {
    return false;
  }
  if (trimmed.contains("'\$err'") ||
      trimmed.contains('"\$err"') ||
      (trimmed.contains('.toString()') &&
          (trimmed.contains('AppSnack') ||
              trimmed.contains('ApiErrorBanner') ||
              trimmed.contains('AppInlineBanner') ||
              trimmed.contains('Text(')))) {
    return true;
  }
  if (!trimmed.contains('.message')) {
    return false;
  }
  if (trimmed.contains('messageStream') ||
      trimmed.contains('messageType') ||
      trimmed.contains('messageId') ||
      trimmed.contains('EventChatMessage') ||
      trimmed.contains('report_detail_status_banner') ||
      trimmed.contains('required this.message')) {
    return false;
  }
  const List<String> suspicious = <String>[
    'e.message',
    'error.message',
    'error?.message',
    'err.message',
    'apiError!.message',
    'apiError?.message',
    'loadError!.message',
    'profileLoadError!.message',
  ];
  for (final String token in suspicious) {
    if (trimmed.contains(token)) {
      return true;
    }
  }
  if (trimmed.contains('AppSnack.show') && trimmed.contains('.message')) {
    return true;
  }
  if (trimmed.contains('ApiErrorBanner') && trimmed.contains('.message')) {
    return true;
  }
  return false;
}

void main() {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('lib/ not found (run from apps/mobile).');
    exit(2);
  }
  final List<String> roots = <String>[
    ...allFeatureLibRoots()
        .map((String root) => '$root/src/presentation')
        .where((String path) => Directory(path).existsSync()),
    if (Directory(
      'packages/chisto_infrastructure/lib/shared/widgets',
    ).existsSync())
      'packages/chisto_infrastructure/lib/shared/widgets',
  ];
  final List<String> hits = scanDartRoots(
    roots: roots,
    skipPathFragments: _skipPathFragments,
    matchesLine: _matchesLine,
  );
  exit(
    runRatchetingAllowlistCheck(
      patternDescription: 'Raw error.message in UI',
      hits: hits,
      allowlistPath: 'tool/raw_error_message_ui_allowlist.txt',
      fixHint:
          'Use localizedAppErrorMessage(l10n, error) or AppSnack.failure(context, error: e).',
    ),
  );
}
