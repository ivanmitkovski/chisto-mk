import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';

/// Mirrors [PatchPublicEventDto] / API limits for edit-event client validation.
const int kEditEventTitleMinLength = 3;
const int kEditEventTitleMaxLength = 200;
const int kEditEventDescriptionMaxLength = 10000;
const int kEditEventMaxParticipantsMin = 2;
const int kEditEventMaxParticipantsMax = 5000;
const int kEditEventGearMaxCount = 20;

/// Immutable snapshot of the form for dirty detection and partial PATCH.
class EditEventFormSnapshot {
  const EditEventFormSnapshot({
    required this.title,
    required this.description,
    required this.maxParticipants,
    required this.dateOnly,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.gearNamesSorted,
    required this.scale,
    required this.difficulty,
  });

  final String title;
  final String description;
  final int? maxParticipants;
  final DateTime dateOnly;
  final EventTime startTime;
  final EventTime endTime;
  final EcoEventCategory category;
  final List<String> gearNamesSorted;
  final CleanupScale scale;
  final EventDifficulty difficulty;

  factory EditEventFormSnapshot.fromEvent(EcoEvent event) {
    final List<String> gear = event.gear.map((EventGear g) => g.name).toList()..sort();
    return EditEventFormSnapshot(
      title: event.title.trim(),
      description: event.description.trim(),
      maxParticipants: event.maxParticipants,
      dateOnly: DateUtils.dateOnly(event.date),
      startTime: event.startTime,
      endTime: event.endTime,
      category: event.category,
      gearNamesSorted: gear,
      scale: event.scale ?? CleanupScale.small,
      difficulty: event.difficulty ?? EventDifficulty.easy,
    );
  }

  bool matches({
    required String titleTrimmed,
    required String descriptionTrimmed,
    required int? maxParticipants,
    required DateTime dateOnly,
    required EventTime startTime,
    required EventTime endTime,
    required EcoEventCategory category,
    required Set<EventGear> gear,
    required CleanupScale scale,
    required EventDifficulty difficulty,
  }) {
    final List<String> gearNow = gear.map((EventGear g) => g.name).toList()..sort();
    if (titleTrimmed != title) return false;
    if (descriptionTrimmed != description) return false;
    if (maxParticipants != this.maxParticipants) return false;
    if (dateOnly != this.dateOnly) return false;
    if (startTime != this.startTime) return false;
    if (endTime != this.endTime) return false;
    if (category != this.category) return false;
    if (scale != this.scale) return false;
    if (difficulty != this.difficulty) return false;
    if (gearNow.length != gearNamesSorted.length) return false;
    for (int i = 0; i < gearNow.length; i++) {
      if (gearNow[i] != gearNamesSorted[i]) return false;
    }
    return true;
  }

  /// Builds a PATCH payload with only fields that differ from [current] values.
  EventUpdatePayload buildPartialPayload({
    required String titleTrimmed,
    required String descriptionTrimmed,
    required int? maxParticipants,
    required DateTime scheduledAtUtc,
    required DateTime endAtUtc,
    required EcoEventCategory category,
    required List<EventGear> gear,
    required CleanupScale scale,
    required EventDifficulty difficulty,
  }) {
    final bool maxChanged = maxParticipants != this.maxParticipants;
    return EventUpdatePayload(
      title: titleTrimmed != title ? titleTrimmed : null,
      description: descriptionTrimmed != description ? descriptionTrimmed : null,
      maxParticipants: maxChanged ? maxParticipants : null,
      includeMaxParticipantsInBody: maxChanged,
      scheduledAtUtc: _scheduledChanged(scheduledAtUtc) ? scheduledAtUtc : null,
      endAtUtc: _endChanged(endAtUtc) ? endAtUtc : null,
      category: category != this.category ? category : null,
      gear: _gearChanged(gear) ? gear : null,
      scale: scale != this.scale ? scale : null,
      difficulty: difficulty != this.difficulty ? difficulty : null,
    );
  }

  bool _scheduledChanged(DateTime nextUtc) {
    final DateTime prevUtc = DateTime(
      dateOnly.year,
      dateOnly.month,
      dateOnly.day,
      startTime.hour,
      startTime.minute,
    ).toUtc();
    return prevUtc != nextUtc;
  }

  bool _endChanged(DateTime nextUtc) {
    final DateTime prevUtc = DateTime(
      dateOnly.year,
      dateOnly.month,
      dateOnly.day,
      endTime.hour,
      endTime.minute,
    ).toUtc();
    return prevUtc != nextUtc;
  }

  bool _gearChanged(List<EventGear> gear) {
    final List<String> now = gear.map((EventGear g) => g.name).toList()..sort();
    if (now.length != gearNamesSorted.length) return true;
    for (int i = 0; i < now.length; i++) {
      if (now[i] != gearNamesSorted[i]) return true;
    }
    return false;
  }
}

/// Title validation: returns null if OK.
String? editEventTitleIssueKey(String trimmed) {
  if (trimmed.length < kEditEventTitleMinLength) {
    return 'tooShort';
  }
  if (trimmed.length > kEditEventTitleMaxLength) {
    return 'tooLong';
  }
  return null;
}

/// Description validation: returns null if OK.
String? editEventDescriptionIssueKey(String trimmed) {
  if (trimmed.length > kEditEventDescriptionMaxLength) {
    return 'tooLong';
  }
  return null;
}

/// Max participants: empty field means unlimited (`null`). Returns issue key or null if OK.
String? editEventMaxParticipantsIssueKey(String fieldTextTrimmed) {
  if (fieldTextTrimmed.isEmpty) {
    return null;
  }
  final int? n = int.tryParse(fieldTextTrimmed);
  if (n == null) {
    return 'invalid';
  }
  if (n < kEditEventMaxParticipantsMin || n > kEditEventMaxParticipantsMax) {
    return 'range';
  }
  return null;
}

int? editEventParsedMaxParticipants(String fieldTextTrimmed) {
  if (fieldTextTrimmed.isEmpty) {
    return null;
  }
  return int.tryParse(fieldTextTrimmed);
}
