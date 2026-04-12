import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Fields for `PATCH /events/:id` (matches [PatchPublicEventDto] on the API).
///
/// Only non-null fields are sent in the JSON body.
class EventUpdatePayload {
  const EventUpdatePayload({
    this.title,
    this.description,
    this.category,
    this.scheduledAtUtc,
    this.endAtUtc,
    this.maxParticipants,
    this.gear,
    this.scale,
    this.difficulty,
  });

  final String? title;
  final String? description;
  final EcoEventCategory? category;
  final DateTime? scheduledAtUtc;
  final DateTime? endAtUtc;
  final int? maxParticipants;
  final List<EventGear>? gear;
  final CleanupScale? scale;
  final EventDifficulty? difficulty;

  Map<String, dynamic> toPatchJson() {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (title != null) {
      body['title'] = title;
    }
    if (description != null) {
      body['description'] = description;
    }
    if (category != null) {
      body['category'] = category!.name;
    }
    if (scheduledAtUtc != null) {
      body['scheduledAt'] = scheduledAtUtc!.toUtc().toIso8601String();
    }
    if (endAtUtc != null) {
      body['endAt'] = endAtUtc!.toUtc().toIso8601String();
    }
    if (maxParticipants != null) {
      body['maxParticipants'] = maxParticipants;
    }
    if (gear != null) {
      body['gear'] = gear!.map((EventGear g) => g.name).toList(growable: false);
    }
    if (scale != null) {
      body['scale'] = scale!.name;
    }
    if (difficulty != null) {
      body['difficulty'] = difficulty!.name;
    }
    return body;
  }
}
