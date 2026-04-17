import 'package:chisto_mobile/core/errors/app_error.dart';

/// Minimal shape from API `details` when [AppError.code] is `DUPLICATE_EVENT`.
class DuplicateEventConflictUi {
  const DuplicateEventConflictUi({
    required this.eventId,
    required this.title,
    required this.scheduledAt,
  });

  final String eventId;
  final String title;
  final DateTime scheduledAt;
}

DuplicateEventConflictUi? duplicateEventConflictUiFromAppError(AppError error) {
  if (error.code != 'DUPLICATE_EVENT') {
    return null;
  }
  final dynamic details = error.details;
  if (details is! Map) {
    return null;
  }
  final Map<String, dynamic> root = Map<String, dynamic>.from(details);
  final dynamic raw = root['conflictingEvent'];
  if (raw is! Map) {
    return null;
  }
  final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
  final String? id = row['id'] as String?;
  final String? title = row['title'] as String?;
  final String? scheduledAtStr = row['scheduledAt'] as String?;
  if (id == null || title == null || scheduledAtStr == null) {
    return null;
  }
  final DateTime? at = DateTime.tryParse(scheduledAtStr);
  if (at == null) {
    return null;
  }
  return DuplicateEventConflictUi(eventId: id, title: title, scheduledAt: at);
}
