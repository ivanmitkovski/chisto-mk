import 'dart:async';
import 'dart:convert';

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

  /// Appends an entry to the queue. Safe to call from any isolate-safe context.
  Future<void> enqueue(CheckInQueueEntry entry) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<CheckInQueueEntry> current = await _load(prefs);
    // De-duplicate: don't enqueue the same qrPayload twice.
    if (current.any((CheckInQueueEntry e) => e.qrPayload == entry.qrPayload)) {
      return;
    }
    current.add(entry);
    await _save(prefs, current);
  }

  /// Returns all pending entries (oldest first).
  Future<List<CheckInQueueEntry>> peek() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _load(prefs);
  }

  /// Removes a specific entry by [qrPayload] after a successful or terminal sync.
  Future<void> remove(String qrPayload) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<CheckInQueueEntry> current = await _load(prefs);
    current.removeWhere((CheckInQueueEntry e) => e.qrPayload == qrPayload);
    await _save(prefs, current);
  }

  /// Removes all entries. Use with caution (testing / logout).
  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  Future<List<CheckInQueueEntry>> _load(SharedPreferences prefs) {
    final String? raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return Future<List<CheckInQueueEntry>>.value(<CheckInQueueEntry>[]);
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return Future<List<CheckInQueueEntry>>.value(
        list
            .whereType<Map<String, dynamic>>()
            .map(CheckInQueueEntry.fromJson)
            .toList(),
      );
    } on Object {
      return Future<List<CheckInQueueEntry>>.value(<CheckInQueueEntry>[]);
    }
  }

  Future<void> _save(SharedPreferences prefs, List<CheckInQueueEntry> entries) {
    final String json = jsonEncode(
      entries.map((CheckInQueueEntry e) => e.toJson()).toList(),
    );
    return prefs.setString(_prefKey, json).then((_) {});
  }
}
