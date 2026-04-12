/// Analytics data for a single cleanup event (organizer-only view).
class EventAnalytics {
  const EventAnalytics({
    required this.totalJoiners,
    required this.checkedInCount,
    required this.attendanceRate,
    required this.joinersOverTime,
    required this.checkInsByHour,
  });

  /// Total number of participants who joined the event.
  final int totalJoiners;

  /// Number of attendees who physically checked in.
  final int checkedInCount;

  /// Attendance rate as a percentage (0–100).
  final int attendanceRate;

  /// Daily cumulative joiner counts (date → count).
  final List<JoinersOverTimeEntry> joinersOverTime;

  /// Check-in volume per hour of the day (0–23).
  final List<CheckInsByHourEntry> checkInsByHour;

  factory EventAnalytics.fromJson(Map<String, dynamic> json) {
    return EventAnalytics(
      totalJoiners: (json['totalJoiners'] as num?)?.toInt() ?? 0,
      checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toInt() ?? 0,
      joinersOverTime: ((json['joinersOverTime'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JoinersOverTimeEntry.fromJson)
          .toList(growable: false),
      checkInsByHour: ((json['checkInsByHour'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CheckInsByHourEntry.fromJson)
          .toList(growable: false),
    );
  }
}

class JoinersOverTimeEntry {
  const JoinersOverTimeEntry({required this.date, required this.count});
  final DateTime date;
  final int count;

  factory JoinersOverTimeEntry.fromJson(Map<String, dynamic> json) {
    return JoinersOverTimeEntry(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CheckInsByHourEntry {
  const CheckInsByHourEntry({required this.hour, required this.count});
  final int hour;
  final int count;

  factory CheckInsByHourEntry.fromJson(Map<String, dynamic> json) {
    return CheckInsByHourEntry(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
