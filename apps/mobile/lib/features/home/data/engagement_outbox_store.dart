import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum EngagementOutboxKind {
  upvote,
  removeUpvote,
  save,
  unsave,
}

/// One persisted engagement mutation to retry after connectivity returns.
class EngagementOutboxEntry {
  const EngagementOutboxEntry({
    required this.id,
    required this.kind,
    required this.siteId,
    required this.enqueuedAtMs,
    this.failCount = 0,
  });

  final String id;
  final EngagementOutboxKind kind;
  final String siteId;
  final int enqueuedAtMs;
  final int failCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'siteId': siteId,
        'enqueuedAtMs': enqueuedAtMs,
        'failCount': failCount,
      };

  static EngagementOutboxKind? _parseKind(Object? raw) {
    final String s = '$raw'.trim();
    for (final EngagementOutboxKind k in EngagementOutboxKind.values) {
      if (k.name == s) {
        return k;
      }
    }
    return null;
  }

  static EngagementOutboxEntry? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final String id = '${json['id'] ?? ''}'.trim();
    final String siteId = '${json['siteId'] ?? ''}'.trim();
    if (id.isEmpty || siteId.isEmpty) return null;
    final EngagementOutboxKind? parsedKind = _parseKind(json['kind']);
    if (parsedKind == null) return null;
    final int enqueuedAtMs = (json['enqueuedAtMs'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final int failCount = (json['failCount'] as num?)?.toInt() ?? 0;
    return EngagementOutboxEntry(
      id: id,
      kind: parsedKind,
      siteId: siteId,
      enqueuedAtMs: enqueuedAtMs,
      failCount: failCount,
    );
  }
}

/// SharedPreferences-backed FIFO queue for offline upvote/save intents.
class EngagementOutboxStore {
  EngagementOutboxStore._();

  static final EngagementOutboxStore _instance = EngagementOutboxStore._();
  static EngagementOutboxStore get instance => _instance;

  static const String _prefKey = 'engagement_outbox_v1';
  static const int _maxEntries = 40;

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

  List<EngagementOutboxEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <EngagementOutboxEntry>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return <EngagementOutboxEntry>[];
      }
      final List<EngagementOutboxEntry> out = <EngagementOutboxEntry>[];
      for (final Object? e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final EngagementOutboxEntry? row = EngagementOutboxEntry.fromJson(e);
        if (row != null) {
          out.add(row);
        }
      }
      return out;
    } on FormatException {
      return <EngagementOutboxEntry>[];
    }
  }

  Future<List<EngagementOutboxEntry>> peek() => _serialized(() async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        return _decode(prefs.getString(_prefKey));
      });

  Future<void> enqueue(EngagementOutboxEntry entry) => _serialized(() async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<EngagementOutboxEntry> current = _decode(prefs.getString(_prefKey));
        current.removeWhere(
          (EngagementOutboxEntry e) =>
              e.siteId == entry.siteId &&
              e.kind == entry.kind,
        );
        current.add(entry);
        while (current.length > _maxEntries) {
          current.removeAt(0);
        }
        await prefs.setString(
          _prefKey,
          jsonEncode(current.map((EngagementOutboxEntry e) => e.toJson()).toList()),
        );
      });

  Future<void> removeById(String id) => _serialized(() async {
        if (id.isEmpty) return;
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<EngagementOutboxEntry> current = _decode(prefs.getString(_prefKey));
        current.removeWhere((EngagementOutboxEntry e) => e.id == id);
        await prefs.setString(
          _prefKey,
          jsonEncode(current.map((EngagementOutboxEntry e) => e.toJson()).toList()),
        );
      });

  /// Increments [failCount] for a retryable flush failure; drops the entry after [maxFailures].
  Future<void> recordRetryableFlushFailure(
    String id, {
    int maxFailures = 5,
  }) =>
      _serialized(() async {
        if (id.isEmpty) return;
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<EngagementOutboxEntry> current = _decode(prefs.getString(_prefKey));
        final int index = current.indexWhere((EngagementOutboxEntry e) => e.id == id);
        if (index < 0) return;
        final EngagementOutboxEntry e = current[index];
        final int next = e.failCount + 1;
        if (next >= maxFailures) {
          current.removeAt(index);
        } else {
          current[index] = EngagementOutboxEntry(
            id: e.id,
            kind: e.kind,
            siteId: e.siteId,
            enqueuedAtMs: e.enqueuedAtMs,
            failCount: next,
          );
        }
        await prefs.setString(
          _prefKey,
          jsonEncode(current.map((EngagementOutboxEntry x) => x.toJson()).toList()),
        );
      });

  static Future<void> enqueueUpvoteIntent({
    required String siteId,
    required bool wantUpvoted,
  }) {
    final EngagementOutboxEntry entry = EngagementOutboxEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}_${siteId}_${wantUpvoted ? 1 : 0}',
      kind: wantUpvoted ? EngagementOutboxKind.upvote : EngagementOutboxKind.removeUpvote,
      siteId: siteId,
      enqueuedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    return instance.enqueue(entry);
  }

  static Future<void> enqueueSaveIntent({
    required String siteId,
    required bool wantSaved,
  }) {
    final EngagementOutboxEntry entry = EngagementOutboxEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}_${siteId}_s${wantSaved ? 1 : 0}',
      kind: wantSaved ? EngagementOutboxKind.save : EngagementOutboxKind.unsave,
      siteId: siteId,
      enqueuedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    return instance.enqueue(entry);
  }
}
