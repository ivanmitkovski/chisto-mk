import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';

WeeklyRankingsResult weeklyRankingsFromJson(Map<String, dynamic> json) {
  final String weekStartsAt = json['weekStartsAt'] as String? ?? '';
  final String weekEndsAt = json['weekEndsAt'] as String? ?? '';
  final int? myRank = (json['myRank'] as num?)?.toInt();
  final int myWeeklyPoints = (json['myWeeklyPoints'] as num?)?.toInt() ?? 0;

  final List<dynamic> raw =
      json['entries'] as List<dynamic>? ?? <dynamic>[];
  final List<WeeklyLeaderboardEntry> entries = raw
      .whereType<Map<String, dynamic>>()
      .map((Map<String, dynamic> e) {
        return WeeklyLeaderboardEntry(
          rank: (e['rank'] as num?)?.toInt() ?? 0,
          userId: e['userId'] as String? ?? '',
          displayName: (e['displayName'] as String?)?.trim() ?? '',
          weeklyPoints: (e['weeklyPoints'] as num?)?.toInt() ?? 0,
          isCurrentUser: e['isCurrentUser'] as bool? ?? false,
        );
      })
      .toList();

  return WeeklyRankingsResult(
    weekStartsAt: weekStartsAt,
    weekEndsAt: weekEndsAt,
    entries: entries,
    myRank: myRank,
    myWeeklyPoints: myWeeklyPoints,
  );
}
