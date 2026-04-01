class WeeklyLeaderboardEntry {
  const WeeklyLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.weeklyPoints,
    required this.isCurrentUser,
  });

  final int rank;
  final String userId;
  final String displayName;
  final int weeklyPoints;
  final bool isCurrentUser;
}

class WeeklyRankingsResult {
  const WeeklyRankingsResult({
    required this.weekStartsAt,
    required this.weekEndsAt,
    required this.entries,
    required this.myRank,
    required this.myWeeklyPoints,
  });

  final String weekStartsAt;
  final String weekEndsAt;
  final List<WeeklyLeaderboardEntry> entries;
  final int? myRank;
  final int myWeeklyPoints;
}
