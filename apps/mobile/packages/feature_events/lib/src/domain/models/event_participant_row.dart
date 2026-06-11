import 'package:meta/meta.dart';

/// A user who joined the event via [EventParticipant] (organizer is separate on [EcoEvent]).
@immutable
class EventParticipantRow {
  const EventParticipantRow({
    required this.userId,
    required this.displayName,
    this.isDeleted = false,
    required this.joinedAt,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final bool isDeleted;
  final DateTime joinedAt;
  final String? avatarUrl;
}

@immutable
class EventParticipantsPage {
  const EventParticipantsPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<EventParticipantRow> items;
  final bool hasMore;
  final String? nextCursor;
}
