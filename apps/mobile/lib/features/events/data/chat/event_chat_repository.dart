import 'dart:typed_data';

import 'package:chisto_mobile/features/events/data/chat/event_chat_connection_status.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_fetch_result.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_participants.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_read_cursor.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_stream_event.dart';

class UploadableFile {
  const UploadableFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

/// Event-scoped participant chat (REST history + SSE live updates).
abstract class EventChatRepository {
  Future<EventChatFetchResult> fetchMessages(
    String eventId, {
    String? cursor,
    int limit = 50,
  });

  Future<EventChatMessage> sendMessage(
    String eventId,
    String body, {
    String? replyToId,
    List<EventChatAttachment>? attachments,
    double? locationLat,
    double? locationLng,
    String? locationLabel,
    String? clientMessageId,
  });

  Future<List<EventChatAttachment>> uploadAttachments(
    String eventId,
    List<UploadableFile> files, {
    void Function(int sent, int total)? onSendProgress,
    bool Function()? isCancelled,
  });

  Future<EventChatMessage> editMessage(
    String eventId,
    String messageId,
    String body,
  );

  Future<void> deleteMessage(String eventId, String messageId);

  Future<EventChatMessage> setPin(
    String eventId,
    String messageId, {
    required bool pinned,
  });

  Future<List<EventChatMessage>> fetchPinnedMessages(String eventId);

  Future<void> markRead(String eventId, String? lastReadMessageId);

  Future<int> fetchUnreadCount(String eventId);

  Future<bool> fetchMuteStatus(String eventId);

  Future<void> setMuteStatus(String eventId, bool muted);

  Future<EventChatParticipantsResult> fetchParticipants(String eventId);

  Future<List<EventChatReadCursor>> fetchReadCursors(String eventId);

  Future<void> setTyping(String eventId, bool typing);

  Future<EventChatFetchResult> searchMessages(
    String eventId,
    String query, {
    String? cursor,
    int limit = 20,
  });

  /// Live updates while the returned stream has listeners. Stops when cancelled.
  Stream<EventChatStreamEvent> messageStream(String eventId);

  /// Connection lifecycle for UI (banner). Stops when cancelled.
  Stream<EventChatConnectionStatus> connectionStatus(String eventId);
}
