import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _kPendingChatRepliesKey = 'pending_chat_replies_v1';

/// Queued inline chat replies when send cannot run in the current isolate.
class PendingChatReply {
  const PendingChatReply({
    required this.eventId,
    required this.body,
    this.notificationId,
    this.enqueuedAtMs,
  });

  final String eventId;
  final String body;
  final String? notificationId;
  final int? enqueuedAtMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'eventId': eventId,
    'body': body,
    if (notificationId != null) 'notificationId': notificationId,
    if (enqueuedAtMs != null) 'enqueuedAtMs': enqueuedAtMs,
  };

  static PendingChatReply? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
    final String eventId = (m['eventId'] as String?)?.trim() ?? '';
    final String body = (m['body'] as String?)?.trim() ?? '';
    if (eventId.isEmpty || body.isEmpty) return null;
    return PendingChatReply(
      eventId: eventId,
      body: body,
      notificationId: m['notificationId'] as String?,
      enqueuedAtMs: (m['enqueuedAtMs'] as num?)?.toInt(),
    );
  }
}

abstract final class PendingChatReplyStore {
  static Future<void> enqueue(PendingChatReply item) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<PendingChatReply> existing = await peekAll();
    existing.add(
      PendingChatReply(
        eventId: item.eventId,
        body: item.body,
        notificationId: item.notificationId,
        enqueuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await prefs.setString(
      _kPendingChatRepliesKey,
      jsonEncode(existing.map((PendingChatReply e) => e.toJson()).toList()),
    );
  }

  static Future<List<PendingChatReply>> peekAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kPendingChatRepliesKey);
    if (raw == null || raw.isEmpty) return <PendingChatReply>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <PendingChatReply>[];
      return decoded
          .map(PendingChatReply.fromJson)
          .whereType<PendingChatReply>()
          .toList();
    } on Object {
      return <PendingChatReply>[];
    }
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingChatRepliesKey);
  }

  static Future<List<PendingChatReply>> drainAll() async {
    final List<PendingChatReply> items = await peekAll();
    await clear();
    return items;
  }
}
