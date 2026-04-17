import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Normalizes public API payloads into the shape [EcoEvent.fromJson] expects.
///
/// The API returns `scheduledAt` / `endAt` (ISO 8601); the mobile model uses
/// calendar `date` plus `startTime` / `endTime` maps when decoding from cache.
///
/// Returns `null` when [json] contains unparseable date strings that make the
/// event meaningless (e.g. `scheduledAt` is a non-ISO value).
EcoEvent? ecoEventFromJson(Map<String, dynamic> json) {
  final Map<String, dynamic> merged = Map<String, dynamic>.from(json);

  final bool hasScheduled = json['scheduledAt'] is String;
  if (hasScheduled) {
    merged['scheduledAtUtc'] = json['scheduledAt'];
  }
  if (hasScheduled && json['date'] == null) {
    final DateTime? start =
        DateTime.tryParse(json['scheduledAt'] as String)?.toLocal();
    if (start == null) return null;

    merged['date'] = DateTime(start.year, start.month, start.day).toIso8601String();

    merged['startTime'] = <String, int>{
      'hour': start.hour,
      'minute': start.minute,
    };

    DateTime end;
    if (json['endAt'] is String) {
      end = DateTime.tryParse(json['endAt'] as String)?.toLocal() ??
          start.add(const Duration(hours: 2));
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
      .whereType<EcoEvent>()
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
