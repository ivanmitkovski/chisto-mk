/// Server preview for GET `/events/check-conflict` and `details` on 409 `DUPLICATE_EVENT`.
class ConflictingEventInfo {
  const ConflictingEventInfo({
    required this.id,
    required this.title,
    required this.scheduledAt,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
}

class EventScheduleConflictPreview {
  const EventScheduleConflictPreview({
    required this.hasConflict,
    this.conflictingEvent,
  });

  final bool hasConflict;
  final ConflictingEventInfo? conflictingEvent;
}

ConflictingEventInfo? conflictingEventFromNestedJson(dynamic raw) {
  if (raw is! Map) {
    return null;
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  final String? id = map['id'] as String?;
  final String? title = map['title'] as String?;
  final String? scheduledAtStr = map['scheduledAt'] as String?;
  if (id == null || title == null || scheduledAtStr == null) {
    return null;
  }
  final DateTime? at = DateTime.tryParse(scheduledAtStr);
  if (at == null) {
    return null;
  }
  return ConflictingEventInfo(id: id, title: title, scheduledAt: at);
}

ConflictingEventInfo? conflictingEventFromDuplicateErrorDetails(dynamic details) {
  if (details is! Map) {
    return null;
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(details);
  return conflictingEventFromNestedJson(map['conflictingEvent']);
}
