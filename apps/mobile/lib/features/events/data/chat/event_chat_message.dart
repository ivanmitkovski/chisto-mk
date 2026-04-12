import 'package:flutter/foundation.dart';

/// Normalizes decoded JSON maps (e.g. Socket.IO) where keys are not `String` typed.
Map<String, dynamic>? _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (Object? k, Object? val) => MapEntry(k.toString(), val),
    );
  }
  return null;
}

/// Server-backed event chat message (REST + SSE).
enum EventChatMessageType {
  text,
  system,
  image,
  location,
  video,
  audio,
  file,
}

@immutable
class EventChatAttachment {
  const EventChatAttachment({
    required this.id,
    required this.url,
    required this.mimeType,
    required this.fileName,
    required this.sizeBytes,
    this.width,
    this.height,
    this.duration,
    this.thumbnailUrl,
  });

  final String id;
  final String url;
  final String mimeType;
  final String fileName;
  final int sizeBytes;
  final int? width;
  final int? height;
  final int? duration;
  final String? thumbnailUrl;

  static EventChatAttachment? tryFromJson(Object? json) {
    final Map<String, dynamic>? map = _jsonMap(json);
    if (map == null) return null;
    final Object? url = map['url'];
    if (url is! String || url.isEmpty) return null;
    // POST /events/:id/chat/upload returns ProcessedAttachment rows without DB id yet.
    final String id = map['id'] is String ? map['id'] as String : '';
    return EventChatAttachment(
      id: id,
      url: url,
      mimeType: map['mimeType'] as String? ?? 'image/webp',
      fileName: map['fileName'] as String? ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      duration: (map['duration'] as num?)?.toInt(),
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'url': url,
    'mimeType': mimeType,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'width': width,
    'height': height,
    'duration': duration,
    'thumbnailUrl': thumbnailUrl,
  };
}

@immutable
class EventChatMessage {
  const EventChatMessage({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.createdAt,
    this.body,
    required this.isDeleted,
    required this.isOwnMessage,
    this.replyToId,
    this.replyToSnippet,
    this.pending = false,
    this.failed = false,
    this.editedAt,
    this.isPinned = false,
    this.messageType = EventChatMessageType.text,
    this.systemPayload,
    this.pinnedByDisplayName,
    this.attachments = const <EventChatAttachment>[],
    this.locationLat,
    this.locationLng,
    this.locationLabel,
    this.clientMessageId,
  });

  final String id;
  final String eventId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final DateTime createdAt;
  final String? body;
  final bool isDeleted;
  final bool isOwnMessage;
  final String? replyToId;
  final String? replyToSnippet;
  final bool pending;
  final bool failed;
  final DateTime? editedAt;
  final bool isPinned;
  final EventChatMessageType messageType;
  final Map<String, dynamic>? systemPayload;
  final String? pinnedByDisplayName;
  final List<EventChatAttachment> attachments;
  final double? locationLat;
  final double? locationLng;
  final String? locationLabel;

  /// Matches server `clientMessageId` for optimistic ↔ realtime merge and idempotent sends.
  final String? clientMessageId;

  EventChatMessage copyWith({
    String? id,
    String? eventId,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    DateTime? createdAt,
    String? body,
    bool? isDeleted,
    bool? isOwnMessage,
    String? replyToId,
    String? replyToSnippet,
    bool? pending,
    bool? failed,
    DateTime? editedAt,
    bool? isPinned,
    EventChatMessageType? messageType,
    Map<String, dynamic>? systemPayload,
    String? pinnedByDisplayName,
    List<EventChatAttachment>? attachments,
    double? locationLat,
    double? locationLng,
    String? locationLabel,
    String? clientMessageId,
  }) {
    return EventChatMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      body: body ?? this.body,
      isDeleted: isDeleted ?? this.isDeleted,
      isOwnMessage: isOwnMessage ?? this.isOwnMessage,
      replyToId: replyToId ?? this.replyToId,
      replyToSnippet: replyToSnippet ?? this.replyToSnippet,
      pending: pending ?? this.pending,
      failed: failed ?? this.failed,
      editedAt: editedAt ?? this.editedAt,
      isPinned: isPinned ?? this.isPinned,
      messageType: messageType ?? this.messageType,
      systemPayload: systemPayload ?? this.systemPayload,
      pinnedByDisplayName: pinnedByDisplayName ?? this.pinnedByDisplayName,
      attachments: attachments ?? this.attachments,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationLabel: locationLabel ?? this.locationLabel,
      clientMessageId: clientMessageId ?? this.clientMessageId,
    );
  }

  static EventChatMessageType _parseMessageType(Object? v) {
    if (v == 'SYSTEM') return EventChatMessageType.system;
    if (v == 'IMAGE') return EventChatMessageType.image;
    if (v == 'LOCATION') return EventChatMessageType.location;
    if (v == 'VIDEO') return EventChatMessageType.video;
    if (v == 'AUDIO') return EventChatMessageType.audio;
    if (v == 'FILE') return EventChatMessageType.file;
    return EventChatMessageType.text;
  }

  static Map<String, dynamic>? _parseSystemPayload(Object? v) {
    if (v is Map<String, dynamic>) {
      return v;
    }
    if (v is Map) {
      return v.map((Object? k, Object? val) => MapEntry(k.toString(), val));
    }
    return null;
  }

  static EventChatMessage? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final Object? id = json['id'];
    final Object? eventId = json['eventId'];
    final Object? createdAt = json['createdAt'];
    if (id is! String || eventId is! String || createdAt is! String) {
      return null;
    }
    final Map<String, dynamic>? author = _jsonMap(json['author']);
    final String authorId = author?['id'] is String ? author!['id']! as String : '';
    final String authorName =
        author?['displayName'] is String ? author!['displayName']! as String : '';
    final String? authorAvatarUrl = author?['avatarUrl'] as String?;

    final Map<String, dynamic>? replyTo = _jsonMap(json['replyTo']);
    final String? replyToSnippet = replyTo?['snippet'] is String ? replyTo!['snippet']! as String : null;

    final Object? editedAtRaw = json['editedAt'];
    DateTime? editedAt;
    if (editedAtRaw is String && editedAtRaw.isNotEmpty) {
      editedAt = DateTime.tryParse(editedAtRaw);
    }

    final List<EventChatAttachment> attachments = <EventChatAttachment>[];
    final Object? rawAttachments = json['attachments'];
    if (rawAttachments is List) {
      for (final Object? item in rawAttachments) {
        final EventChatAttachment? a = EventChatAttachment.tryFromJson(item);
        if (a != null) attachments.add(a);
      }
    }

    return EventChatMessage(
      id: id,
      eventId: eventId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
      body: json['body'] as String?,
      isDeleted: json['isDeleted'] == true,
      isOwnMessage: json['isOwnMessage'] == true,
      replyToId: json['replyToId'] as String?,
      replyToSnippet: replyToSnippet,
      editedAt: editedAt,
      isPinned: json['isPinned'] == true,
      messageType: _parseMessageType(json['messageType']),
      systemPayload: _parseSystemPayload(json['systemPayload']),
      pinnedByDisplayName: json['pinnedByDisplayName'] as String?,
      attachments: attachments,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      locationLabel: json['locationLabel'] as String?,
      clientMessageId: json['clientMessageId'] as String?,
    );
  }

  /// Normalizes [isOwnMessage] using the current viewer id (SSE payloads omit correct own flag).
  EventChatMessage withViewer(String? viewerUserId) {
    if (viewerUserId == null || viewerUserId.isEmpty) {
      return this;
    }
    return copyWith(isOwnMessage: authorId == viewerUserId);
  }
}
