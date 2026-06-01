import 'package:feature_events/src/domain/models/event_schedule_conflict_preview.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared schedule overlap check and formatting for create/edit event flows.
class ScheduleConflictUseCase {
  const ScheduleConflictUseCase();

  String formatConflictWhen(BuildContext context, DateTime at) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_jm().format(at.toLocal());
  }

  Future<EventScheduleConflictPreview> checkConflict({
    required EventsRepository repository,
    required String siteId,
    required DateTime startLocal,
    required DateTime endLocal,
    String? excludeEventId,
  }) {
    return repository.checkScheduleConflict(
      siteId: siteId,
      scheduledAt: startLocal.toUtc(),
      endAt: endLocal.toUtc(),
      excludeEventId: excludeEventId,
    );
  }
}
