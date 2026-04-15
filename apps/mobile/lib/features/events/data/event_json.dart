import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Normalizes public API payloads into the shape [EcoEvent.fromJson] expects.
///
/// The API returns `scheduledAt` / `endAt` (ISO 8601); the mobile model uses
/// calendar `date` plus `startTime` / `endTime` maps when decoding from cache.
EcoEvent ecoEventFromJson(Map<String, dynamic> json) {
  final Map<String, dynamic> merged = Map<String, dynamic>.from(json);

  final bool hasScheduled = json['scheduledAt'] is String;
  if (hasScheduled) {
    merged['scheduledAtUtc'] = json['scheduledAt'];
  }
  if (hasScheduled && json['date'] == null) {
    final DateTime start = DateTime.parse(json['scheduledAt'] as String).toLocal();
    merged['date'] = DateTime(start.year, start.month, start.day).toIso8601String();

    merged['startTime'] = <String, int>{
      'hour': start.hour,
      'minute': start.minute,
    };

    DateTime end;
    if (json['endAt'] is String) {
      end = DateTime.parse(json['endAt'] as String).toLocal();
    } else {
      end = start.add(const Duration(hours: 2));
    }
    merged['endTime'] = <String, int>{
      'hour': end.hour,
      'minute': end.minute,
    };
  }

  return EcoEvent.fromJson(merged);
}

List<EcoEvent> ecoEventListFromJson(List<dynamic> list) {
  return list
      .whereType<Map<String, dynamic>>()
      .map(ecoEventFromJson)
      .toList(growable: false);
}

/// Reads `pointsAwarded` from join / check-in API payloads (optional field).
int parsePointsAwardedFromJson(Map<String, dynamic>? json) {
  if (json == null) {
    return 0;
  }
  final Object? p = json['pointsAwarded'];
  if (p is int) {
    return p;
  }
  if (p is num) {
    return p.round();
  }
  return 0;
}
