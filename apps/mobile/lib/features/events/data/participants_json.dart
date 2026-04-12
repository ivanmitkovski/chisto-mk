import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';

EventParticipantsPage eventParticipantsPageFromJson(Map<String, dynamic> json) {
  final List<dynamic> raw = json['data'] as List<dynamic>? ?? <dynamic>[];
  final List<EventParticipantRow> items = raw.map((dynamic e) {
    final Map<String, dynamic> row = e as Map<String, dynamic>;
    final String joinedAtRaw = row['joinedAt'] as String? ?? '';
    final DateTime joinedAt = DateTime.tryParse(joinedAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return EventParticipantRow(
      userId: row['userId'] as String? ?? '',
      displayName: (row['displayName'] as String? ?? '').trim(),
      joinedAt: joinedAt,
      avatarUrl: row['avatarUrl'] as String?,
    );
  }).toList(growable: false);

  final Object? metaRaw = json['meta'];
  final Map<String, dynamic> meta = metaRaw is Map<String, dynamic>
      ? metaRaw
      : <String, dynamic>{};
  final bool hasMore = meta['hasMore'] == true;
  final String? nextCursor = meta['nextCursor'] as String?;

  return EventParticipantsPage(
    items: items,
    hasMore: hasMore,
    nextCursor: nextCursor,
  );
}
