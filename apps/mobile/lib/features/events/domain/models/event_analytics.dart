/// Analytics data for a single cleanup event (organizer-only view).
class EventAnalytics {
  const EventAnalytics({
    required this.totalJoiners,
    required this.checkedInCount,
    required this.attendanceRate,
    required this.joinersCumulative,
    required this.checkInsByHour,
  });

  /// Total number of participants who joined the event (from aggregate).
  final int totalJoiners;

  /// Number of check-in rows (same source as hourly chart).
  final int checkedInCount;

  /// Attendance rate as a percentage (0–100).
  final int attendanceRate;

  /// One point per join, ordered by time, with running cumulative count.
  final List<JoinersCumulativeEntry> joinersCumulative;

  /// Exactly 24 slots (hours 0–23 UTC), zeros where no check-ins.
  final List<CheckInsByHourEntry> checkInsByHour;

  factory EventAnalytics.fromJson(Map<String, dynamic> json) {
    final List<JoinersCumulativeEntry> cumulative = ((json['joinersCumulative'] as List<dynamic>?) ??
            <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(JoinersCumulativeEntry.fromJson)
        .toList(growable: false);

    final List<CheckInsByHourEntry> rawHours = ((json['checkInsByHour'] as List<dynamic>?) ??
            <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CheckInsByHourEntry.fromJson)
        .toList(growable: false);

    return EventAnalytics(
      totalJoiners: (json['totalJoiners'] as num?)?.toInt() ?? 0,
      checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toInt() ?? 0,
      joinersCumulative: cumulative,
      checkInsByHour: _normalizeHours(rawHours),
    );
  }

  static List<CheckInsByHourEntry> _normalizeHours(List<CheckInsByHourEntry> raw) {
    final Map<int, int> byHour = <int, int>{for (final CheckInsByHourEntry e in raw) e.hour: e.count};
    return List<CheckInsByHourEntry>.generate(
      24,
      (int h) => CheckInsByHourEntry(hour: h, count: byHour[h] ?? 0),
      growable: false,
    );
  }
}

class JoinersCumulativeEntry {
  const JoinersCumulativeEntry({required this.at, required this.cumulativeJoiners});

  final DateTime at;
  final int cumulativeJoiners;

  factory JoinersCumulativeEntry.fromJson(Map<String, dynamic> json) {
    return JoinersCumulativeEntry(
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      cumulativeJoiners: (json['cumulativeJoiners'] as num?)?.toInt() ?? 0,
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
