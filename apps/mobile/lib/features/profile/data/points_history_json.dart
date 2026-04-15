import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';

PointsHistoryPage pointsHistoryFromJson(Map<String, dynamic> json) {
  final Object? dataRaw = json['data'];
  final List<dynamic>? rawItems = dataRaw is List<dynamic> ? dataRaw : null;

  final Object? metaRaw = json['meta'];
  final Map<String, dynamic> meta = metaRaw is Map<String, dynamic>
      ? Map<String, dynamic>.from(metaRaw)
      : <String, dynamic>{};
  final List<dynamic>? rawMilestones = meta['milestones'] as List<dynamic>?;

  final List<PointsHistoryEntry> items = <PointsHistoryEntry>[];
  if (rawItems != null) {
    for (final dynamic e in rawItems) {
      if (e is! Map<String, dynamic>) continue;
      final String? id = e['id'] as String?;
      final String? createdAtRaw = e['createdAt'] as String?;
      if (id == null || id.isEmpty || createdAtRaw == null) continue;
      final DateTime? createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) continue;
      items.add(
        PointsHistoryEntry(
          id: id,
          createdAt: createdAt,
          delta: (e['delta'] as num?)?.round() ?? 0,
          reasonCode: (e['reasonCode'] as String?)?.trim() ?? '',
          referenceType: (e['referenceType'] as String?)?.trim(),
          referenceId: (e['referenceId'] as String?)?.trim(),
        ),
      );
    }
  }

  final List<PointsHistoryMilestone> milestones = <PointsHistoryMilestone>[];
  if (rawMilestones != null) {
    for (final dynamic m in rawMilestones) {
      if (m is! Map<String, dynamic>) continue;
      final String? reachedAtRaw = m['reachedAt'] as String?;
      if (reachedAtRaw == null) continue;
      final DateTime? reachedAt = DateTime.tryParse(reachedAtRaw);
      if (reachedAt == null) continue;
      milestones.add(
        PointsHistoryMilestone(
          reachedAt: reachedAt,
          level: (m['level'] as num?)?.round() ?? 1,
          levelTierKey: (m['levelTierKey'] as String?)?.trim() ?? 'numeric_1',
          levelDisplayName:
              (m['levelDisplayName'] as String?)?.trim() ?? 'Level 1',
        ),
      );
    }
  }

  final String? nextCursor = (meta['nextCursor'] as String?)?.trim();
  return PointsHistoryPage(
    items: items,
    milestones: milestones,
    nextCursor: nextCursor != null && nextCursor.isNotEmpty ? nextCursor : null,
  );
}
