import 'dart:async';
import 'dart:convert';

import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single pending offline check-in payload waiting for network connectivity.
class CheckInQueueEntry {
  const CheckInQueueEntry({
    required this.eventId,
    required this.qrPayload,
    required this.enqueuedAt,
  });

  final String eventId;
  final String qrPayload;
  final DateTime enqueuedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'eventId': eventId,
        'qrPayload': qrPayload,
        'enqueuedAt': enqueuedAt.toIso8601String(),
      };

  factory CheckInQueueEntry.fromJson(Map<String, dynamic> json) {
    return CheckInQueueEntry(
      eventId: json['eventId'] as String,
      qrPayload: json['qrPayload'] as String,
      enqueuedAt: DateTime.parse(json['enqueuedAt'] as String),
    );
  }

  @override
  String toString() => 'CheckInQueueEntry(eventId: $eventId, enqueuedAt: $enqueuedAt)';
}

/// [SharedPreferences]-backed FIFO queue of offline check-in payloads.
///
/// Entries are persisted across app restarts and drained by [CheckInSyncService]
/// when connectivity is restored.
class CheckInSyncQueue {
  CheckInSyncQueue._();

  static final CheckInSyncQueue _instance = CheckInSyncQueue._();
  static CheckInSyncQueue get instance => _instance;

  static const String _prefKey = 'chk_sync_queue_v1';

  /// Serializes concurrent access to the queue storage.
  Completer<void>? _lock;

  Future<T> _serialized<T>(Future<T> Function() fn) async {
    while (_lock != null) {
      await _lock!.future;
    }
    _lock = Completer<void>();
    try {
      return await fn();
    } finally {
      final Completer<void> c = _lock!;
      _lock = null;
      c.complete();
    }
  }

  /// Appends an entry to the queue.
  Future<void> enqueue(CheckInQueueEntry entry) => _serialized(() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<CheckInQueueEntry> current = _load(prefs);
    if (current.any((CheckInQueueEntry e) => e.qrPayload == entry.qrPayload)) {
      return;
    }
    current.add(entry);
    await _save(prefs, current);
  });

  /// Returns all pending entries (oldest first).
  Future<List<CheckInQueueEntry>> peek() => _serialized(() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _load(prefs);
  });

  /// Removes a specific entry by [qrPayload] after a successful or terminal sync.
  Future<void> remove(String qrPayload) => _serialized(() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<CheckInQueueEntry> current = _load(prefs);
    current.removeWhere((CheckInQueueEntry e) => e.qrPayload == qrPayload);
    await _save(prefs, current);
  });

  /// Removes all entries. Use with caution (testing / logout).
  Future<void> clear() => _serialized(() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  });

  List<CheckInQueueEntry> _load(SharedPreferences prefs) {
    final String? raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return <CheckInQueueEntry>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final List<CheckInQueueEntry> entries = <CheckInQueueEntry>[];
      for (final dynamic item in list) {
        if (item is Map<String, dynamic>) {
          try {
            entries.add(CheckInQueueEntry.fromJson(item));
          } on Object catch (_) {
            logEventsDiagnostic('check_in_queue_entry_corrupt');
          }
        }
      }
      return entries;
    } on Object catch (_) {
      logEventsDiagnostic('check_in_queue_json_corrupt');
      return <CheckInQueueEntry>[];
    }
  }

  Future<void> _save(SharedPreferences prefs, List<CheckInQueueEntry> entries) {
    final String json = jsonEncode(
      entries.map((CheckInQueueEntry e) => e.toJson()).toList(),
    );
    return prefs.setString(_prefKey, json).then((_) {});
  }
}
