// ignore_for_file: avoid_print

import 'dart:io';

/// Ensures realtime transport classes expose connect/disconnect/dispose lifecycle.
int runRealtimeClientShapeCheck() {
  final List<MapEntry<String, List<String>>> required = <MapEntry<String, List<String>>>[
    MapEntry<String, List<String>>(
      'lib/features/events/data/chat/socket_event_chat_stream.dart',
      <String>['void connect(', 'void disconnect()', 'void dispose()'],
    ),
    MapEntry<String, List<String>>(
      'lib/features/reports/data/reports_realtime/reports_owner_socket_stream.dart',
      <String>['void connect()', 'void stop()', 'void dispose()'],
    ),
    MapEntry<String, List<String>>(
      'lib/features/events/data/socket_check_in_stream.dart',
      <String>['void connect(', 'void disconnect()', 'void dispose()'],
    ),
    MapEntry<String, List<String>>(
      'lib/features/notifications/data/socket_notifications_stream.dart',
      <String>['void connect()', 'void dispose()'],
    ),
    MapEntry<String, List<String>>(
      'lib/features/home/data/map_realtime/map_realtime_service.dart',
      <String>['void requestReconnect()', 'void dispose()'],
    ),
  ];
  final List<String> violations = <String>[];
  for (final MapEntry<String, List<String>> entry in required) {
    final File f = File(entry.key);
    if (!f.existsSync()) {
      violations.add('${entry.key}: missing file');
      continue;
    }
    final String content = f.readAsStringSync();
    for (final String needle in entry.value) {
      if (!content.contains(needle)) {
        violations.add('${entry.key}: missing `$needle`');
      }
    }
    if (content.contains('onListen') && content.contains('.connect(')) {
      // Repository-level double-connect guard lives in api_event_chat_repository.
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln('Realtime client shape:\n${violations.join('\n')}');
    return 1;
  }
  stdout.writeln('OK: realtime client shape.');
  return 0;
}

void main() {
  exit(runRealtimeClientShapeCheck());
}
