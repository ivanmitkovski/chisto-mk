import 'dart:async';

import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_fetch_result.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_participants.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_read_cursor.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_stream_event.dart';

/// In-memory chat for tests and offline demos.
class InMemoryEventChatRepository implements EventChatRepository {
  final Map<String, List<EventChatMessage>> _byEvent = <String, List<EventChatMessage>>{};
  final Map<String, String?> _lastReadByEvent = <String, String?>{};
  final Map<String, Map<String, EventChatReadCursor>> _readCursorsByEvent =
      <String, Map<String, EventChatReadCursor>>{};
  final Map<String, bool> _mutedByEvent = <String, bool>{};
  final StreamController<EventChatStreamEvent> _bus =
      StreamController<EventChatStreamEvent>.broadcast();

  List<EventChatMessage> _messages(String eventId) =>
      _byEvent.putIfAbsent(eventId, () => <EventChatMessage>[]);

  List<EventChatMessage> _sortedNewestFirst(String eventId) {
    final List<EventChatMessage> all = List<EventChatMessage>.from(_messages(eventId));
    all.sort((EventChatMessage a, EventChatMessage b) {
      final int c = b.createdAt.compareTo(a.createdAt);
      if (c != 0) {
        return c;
      }
      return b.id.compareTo(a.id);
    });
    return all;
  }

  @override
  Future<EventChatFetchResult> fetchMessages(
    String eventId, {
    String? cursor,
    int limit = 50,
  }) async {
    final List<EventChatMessage> all = _sortedNewestFirst(eventId);
    final List<EventChatMessage> page;
    bool hasMore = false;
    if (cursor == null || cursor.isEmpty) {
      page = all.take(limit).toList();
      hasMore = all.length > limit;
    } else {
      final int idx = all.indexWhere((EventChatMessage m) => m.id == cursor);
      if (idx < 0) {
        page = <EventChatMessage>[];
        hasMore = false;
      } else {
        final List<EventChatMessage> slice = all.skip(idx + 1).toList();
        page = slice.take(limit).toList();
        hasMore = slice.length > limit;
      }
    }
    final String? nextCursor = page.isNotEmpty ? page.last.id : null;
    return EventChatFetchResult(
      messages: page,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<EventChatFetchResult> searchMessages(
    String eventId,
    String query, {
    String? cursor,
    int limit = 20,
  }) async {
    final String needle = query.trim().toLowerCase();
    final List<EventChatMessage> all = _sortedNewestFirst(eventId).where((EventChatMessage m) {
      final String? b = m.body;
      return b != null && b.toLowerCase().contains(needle);
    }).toList();
    List<EventChatMessage> page;
    bool hasMore = false;
    if (cursor == null || cursor.isEmpty) {
      page = all.take(limit).toList();
      hasMore = all.length > limit;
    } else {
      final int idx = all.indexWhere((EventChatMessage m) => m.id == cursor);
      if (idx < 0) {
        page = <EventChatMessage>[];
        hasMore = false;
      } else {
        final List<EventChatMessage> slice = all.skip(idx + 1).toList();
        page = slice.take(limit).toList();
        hasMore = slice.length > limit;
      }
    }
    final String? nextCursor = page.isNotEmpty ? page.last.id : null;
    return EventChatFetchResult(messages: page, hasMore: hasMore, nextCursor: nextCursor);
  }

  @override
  Future<List<EventChatMessage>> fetchPinnedMessages(String eventId) async {
    return _messages(eventId).where((EventChatMessage m) => m.isPinned && !m.isDeleted).toList()
      ..sort((EventChatMessage a, EventChatMessage b) {
        final DateTime pa = a.createdAt;
        final DateTime pb = b.createdAt;
        return pb.compareTo(pa);
      });
  }

  @override
  Future<List<EventChatAttachment>> uploadAttachments(
    String eventId,
    List<UploadableFile> files, {
    void Function(int sent, int total)? onSendProgress,
    bool Function()? isCancelled,
  }) async {
    final int total = files.fold<int>(0, (int a, UploadableFile f) => a + f.bytes.length);
    int sent = 0;
    for (final UploadableFile f in files) {
      sent += f.bytes.length;
      onSendProgress?.call(sent, total);
      if (isCancelled?.call() == true) {
        return <EventChatAttachment>[];
      }
    }
    final int t = DateTime.now().microsecondsSinceEpoch;
    return files
        .asMap()
        .entries
        .map(
          (MapEntry<int, UploadableFile> e) => EventChatAttachment(
            id: 'local_up_${t}_${e.key}',
            url: 'memory://$eventId/${e.value.fileName}',
            mimeType: e.value.mimeType,
            fileName: e.value.fileName,
            sizeBytes: e.value.bytes.length,
          ),
        )
        .toList();
  }

  @override
  Future<EventChatMessage> sendMessage(
    String eventId,
    String body, {
    String? replyToId,
    List<EventChatAttachment>? attachments,
    double? locationLat,
    double? locationLng,
    String? locationLabel,
    String? clientMessageId,
  }) async {
    final String? cm = clientMessageId?.trim();
    if (cm != null && cm.isNotEmpty) {
      for (final EventChatMessage m in _messages(eventId)) {
        if (m.clientMessageId == cm) {
          return m;
        }
      }
    }
    final String id = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final String trimmed = body.trim();
    final List<EventChatAttachment> attach = attachments ?? const <EventChatAttachment>[];
    EventChatMessageType type = EventChatMessageType.text;
    if (locationLat != null && locationLng != null) {
      type = EventChatMessageType.location;
    } else if (attach.isNotEmpty) {
      final String mime = attach.first.mimeType.toLowerCase();
      if (mime.startsWith('video/')) {
        type = EventChatMessageType.video;
      } else if (mime.startsWith('audio/')) {
        type = EventChatMessageType.audio;
      } else if (mime.startsWith('application/') || mime.startsWith('text/')) {
        type = EventChatMessageType.file;
      } else if (mime.startsWith('image/')) {
        type = EventChatMessageType.image;
      }
    }
    final EventChatMessage msg = EventChatMessage(
      id: id,
      eventId: eventId,
      authorId: 'me',
      authorName: 'You',
      createdAt: DateTime.now().toUtc(),
      body: trimmed.isEmpty ? null : trimmed,
      isDeleted: false,
      isOwnMessage: true,
      replyToId: replyToId,
      messageType: type,
      attachments: attach,
      locationLat: locationLat,
      locationLng: locationLng,
      locationLabel: locationLabel,
      clientMessageId: cm,
    );
    _messages(eventId).add(msg);
    _bus.add(EventChatStreamMessageCreated(msg));
    return msg;
  }

  @override
  Future<EventChatMessage> editMessage(
    String eventId,
    String messageId,
    String body,
  ) async {
    final List<EventChatMessage> list = _messages(eventId);
    final int idx = list.indexWhere((EventChatMessage m) => m.id == messageId);
    if (idx < 0) {
      throw StateError('not found');
    }
    final EventChatMessage u = list[idx].copyWith(
      body: body.trim(),
      editedAt: DateTime.now().toUtc(),
    );
    list[idx] = u;
    _bus.add(EventChatStreamMessageEdited(u));
    return u;
  }

  @override
  Future<EventChatMessage> setPin(
    String eventId,
    String messageId, {
    required bool pinned,
  }) async {
    final List<EventChatMessage> list = _messages(eventId);
    final int idx = list.indexWhere((EventChatMessage m) => m.id == messageId);
    if (idx < 0) {
      throw StateError('not found');
    }
    EventChatMessage u = list[idx].copyWith(
      isPinned: pinned,
      pinnedByDisplayName: pinned ? 'Organizer' : null,
    );
    list[idx] = u;
    if (pinned) {
      _bus.add(EventChatStreamMessagePinned(u));
    } else {
      _bus.add(EventChatStreamMessageUnpinned(u));
    }
    return u;
  }

  /// Test helper: inject a message from another participant.
  Future<EventChatMessage> seedOtherMessage(
    String eventId, {
    required String authorId,
    required String authorName,
    required String body,
    String? replyToId,
    EventChatMessageType type = EventChatMessageType.text,
    Map<String, dynamic>? systemPayload,
  }) async {
    final String id = 'seed_${DateTime.now().microsecondsSinceEpoch}';
    final EventChatMessage msg = EventChatMessage(
      id: id,
      eventId: eventId,
      authorId: authorId,
      authorName: authorName,
      createdAt: DateTime.now().toUtc(),
      body: body,
      isDeleted: false,
      isOwnMessage: false,
      replyToId: replyToId,
      messageType: type,
      systemPayload: systemPayload,
    );
    _messages(eventId).add(msg);
    _bus.add(EventChatStreamMessageCreated(msg));
    return msg;
  }

  @override
  Future<void> deleteMessage(String eventId, String messageId) async {
    final List<EventChatMessage> list = _messages(eventId);
    final int idx = list.indexWhere((EventChatMessage m) => m.id == messageId);
    if (idx < 0) {
      return;
    }
    list[idx] = list[idx].copyWith(isDeleted: true, body: null, isPinned: false);
    _bus.add(EventChatStreamMessageDeleted(messageId));
  }

  @override
  Future<void> markRead(String eventId, String? lastReadMessageId) async {
    _lastReadByEvent[eventId] = lastReadMessageId;
    DateTime? at;
    final String? mid = lastReadMessageId?.trim();
    if (mid != null && mid.isNotEmpty) {
      for (final EventChatMessage m in _messages(eventId)) {
        if (m.id == mid) {
          at = m.createdAt;
          break;
        }
      }
    }
    final EventChatReadCursor cur = EventChatReadCursor(
      userId: 'me',
      displayName: 'You',
      lastReadMessageId: mid,
      lastReadMessageCreatedAt: at,
    );
    _readCursorsByEvent.putIfAbsent(eventId, () => <String, EventChatReadCursor>{})['me'] = cur;
    _bus.add(
      EventChatStreamReadCursorUpdated(
        eventId: eventId,
        userId: 'me',
        displayName: 'You',
        lastReadMessageId: mid,
        lastReadMessageCreatedAt: at,
      ),
    );
  }

  @override
  Future<int> fetchUnreadCount(String eventId) async {
    final String? last = _lastReadByEvent[eventId];
    final List<EventChatMessage> list = _messages(eventId);
    if (last == null || last.isEmpty) {
      return list.where((EventChatMessage m) => !m.isOwnMessage && !m.isDeleted).length;
    }
    EventChatMessage? ref;
    for (final EventChatMessage m in list) {
      if (m.id == last) {
        ref = m;
        break;
      }
    }
    if (ref == null) {
      return list.where((EventChatMessage m) => !m.isOwnMessage && !m.isDeleted).length;
    }
    final EventChatMessage anchor = ref;
    return list
        .where(
          (EventChatMessage m) =>
              !m.isOwnMessage &&
              !m.isDeleted &&
              (m.createdAt.isAfter(anchor.createdAt) ||
                  (m.createdAt == anchor.createdAt && m.id.compareTo(anchor.id) > 0)),
        )
        .length;
  }

  @override
  Future<bool> fetchMuteStatus(String eventId) async {
    return _mutedByEvent[eventId] == true;
  }

  @override
  Future<void> setMuteStatus(String eventId, bool muted) async {
    if (muted) {
      _mutedByEvent[eventId] = true;
    } else {
      _mutedByEvent.remove(eventId);
    }
  }

  @override
  Future<EventChatParticipantsResult> fetchParticipants(String eventId) async {
    final List<EventChatMessage> list = _messages(eventId);
    final Map<String, String> names = <String, String>{};
    final Map<String, String?> avatars = <String, String?>{};
    for (final EventChatMessage m in list) {
      names[m.authorId] = m.authorName;
      final String? u = m.authorAvatarUrl;
      if (u != null && u.isNotEmpty) {
        avatars[m.authorId] = u;
      }
    }
    names['me'] = 'You';
    final List<EventChatParticipantPreview> previews = names.entries
        .map(
          (MapEntry<String, String> e) => EventChatParticipantPreview(
            id: e.key,
            displayName: e.value,
            avatarUrl: avatars[e.key],
          ),
        )
        .toList();
    return EventChatParticipantsResult(count: previews.length, participants: previews.take(50).toList());
  }

  @override
  Future<List<EventChatReadCursor>> fetchReadCursors(String eventId) async {
    final EventChatParticipantsResult p = await fetchParticipants(eventId);
    final Map<String, EventChatReadCursor> byUser = _readCursorsByEvent[eventId] ?? <String, EventChatReadCursor>{};
    return p.participants
        .map(
          (EventChatParticipantPreview x) =>
              byUser[x.id] ?? EventChatReadCursor(userId: x.id, displayName: x.displayName),
        )
        .toList();
  }

  @override
  Future<void> setTyping(String eventId, bool typing) async {}

  @override
  Stream<EventChatStreamEvent> messageStream(String eventId) {
    return _bus.stream.where((EventChatStreamEvent e) {
      if (e is EventChatStreamMessageCreated) {
        return e.message.eventId == eventId;
      }
      if (e is EventChatStreamMessageEdited) {
        return e.message.eventId == eventId;
      }
      if (e is EventChatStreamMessagePinned) {
        return e.message.eventId == eventId;
      }
      if (e is EventChatStreamMessageUnpinned) {
        return e.message.eventId == eventId;
      }
      if (e is EventChatStreamTypingUpdated) {
        return e.eventId == eventId;
      }
      if (e is EventChatStreamReadCursorUpdated) {
        return e.eventId == eventId;
      }
      return true;
    });
  }

  @override
  Stream<EventChatConnectionStatus> connectionStatus(String eventId) {
    return const Stream<EventChatConnectionStatus>.empty();
  }

  /// Test helper: set another member’s read cursor without going through [markRead].
  void setReadCursorForUser(
    String eventId, {
    required String userId,
    required String displayName,
    String? lastReadMessageId,
    DateTime? lastReadMessageCreatedAt,
  }) {
    _readCursorsByEvent.putIfAbsent(eventId, () => <String, EventChatReadCursor>{})[userId] =
        EventChatReadCursor(
      userId: userId,
      displayName: displayName,
      lastReadMessageId: lastReadMessageId,
      lastReadMessageCreatedAt: lastReadMessageCreatedAt,
    );
  }

  void dispose() {
    _bus.close();
  }
}
