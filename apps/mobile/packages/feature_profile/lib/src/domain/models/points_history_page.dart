class PointsHistoryMilestone {
  const PointsHistoryMilestone({
    required this.reachedAt,
    required this.level,
    required this.levelTierKey,
    required this.levelDisplayName,
  });

  final DateTime reachedAt;
  final int level;
  final String levelTierKey;
  final String levelDisplayName;
}

class PointsHistoryEntry {
  const PointsHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.delta,
    required this.reasonCode,
    this.referenceType,
    this.referenceId,
  });

  final String id;
  final DateTime createdAt;
  final int delta;
  final String reasonCode;
  final String? referenceType;
  final String? referenceId;
}

class PointsHistoryPage {
  const PointsHistoryPage({
    required this.items,
    required this.milestones,
    this.nextCursor,
  });

  final List<PointsHistoryEntry> items;
  final List<PointsHistoryMilestone> milestones;
  final String? nextCursor;
}
