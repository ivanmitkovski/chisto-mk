import 'package:flutter/foundation.dart';

@immutable
class EventChatParticipantPreview {
  const EventChatParticipantPreview({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
}

@immutable
class EventChatParticipantsResult {
  const EventChatParticipantsResult({
    required this.count,
    required this.participants,
  });

  final int count;
  final List<EventChatParticipantPreview> participants;
}
