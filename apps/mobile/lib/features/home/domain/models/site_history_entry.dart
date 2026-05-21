/// Chronological site lifecycle entry from `GET /sites/:id/history`.
class SiteHistoryEntry {
  const SiteHistoryEntry({
    required this.id,
    required this.kind,
    required this.occurredAt,
    this.fromStatus,
    this.toStatus,
    this.reportId,
    this.cleanupEventId,
    this.actorDisplayName,
    this.actorRole,
    this.note,
    this.metadata,
  });

  final String id;
  final SiteHistoryEntryKind kind;
  final DateTime occurredAt;
  final String? fromStatus;
  final String? toStatus;
  final String? reportId;
  final String? cleanupEventId;
  final String? actorDisplayName;
  final String? actorRole;
  final String? note;
  final Map<String, dynamic>? metadata;
}

enum SiteHistoryEntryKind {
  siteCreated,
  reportSubmitted,
  reportApproved,
  reportRejected,
  reportMerged,
  statusChanged,
  cleanupEventScheduled,
  cleanupEventStarted,
  cleanupEventCompleted,
  cleanupEventCancelled,
  archivedByAdmin,
  unarchivedByAdmin,
  adminNote,
  unknown,
}

SiteHistoryEntryKind siteHistoryEntryKindFromApi(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'SITE_CREATED':
      return SiteHistoryEntryKind.siteCreated;
    case 'REPORT_SUBMITTED':
      return SiteHistoryEntryKind.reportSubmitted;
    case 'REPORT_APPROVED':
      return SiteHistoryEntryKind.reportApproved;
    case 'REPORT_REJECTED':
      return SiteHistoryEntryKind.reportRejected;
    case 'REPORT_MERGED':
      return SiteHistoryEntryKind.reportMerged;
    case 'STATUS_CHANGED':
      return SiteHistoryEntryKind.statusChanged;
    case 'CLEANUP_EVENT_SCHEDULED':
      return SiteHistoryEntryKind.cleanupEventScheduled;
    case 'CLEANUP_EVENT_STARTED':
      return SiteHistoryEntryKind.cleanupEventStarted;
    case 'CLEANUP_EVENT_COMPLETED':
      return SiteHistoryEntryKind.cleanupEventCompleted;
    case 'CLEANUP_EVENT_CANCELLED':
      return SiteHistoryEntryKind.cleanupEventCancelled;
    case 'ARCHIVED_BY_ADMIN':
      return SiteHistoryEntryKind.archivedByAdmin;
    case 'UNARCHIVED_BY_ADMIN':
      return SiteHistoryEntryKind.unarchivedByAdmin;
    case 'ADMIN_NOTE':
      return SiteHistoryEntryKind.adminNote;
    default:
      return SiteHistoryEntryKind.unknown;
  }
}

class SiteHistoryPage {
  const SiteHistoryPage({
    required this.items,
    this.nextBeforeId,
  });

  final List<SiteHistoryEntry> items;
  final String? nextBeforeId;
}
