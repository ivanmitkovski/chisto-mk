import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// API report status for list/detail display.
enum ApiReportStatus {
  new_,
  inReview,
  approved,
  deleted,
}

/// Report list item from GET /reports/me.
class ReportListItem {
  const ReportListItem({
    required this.id,
    required this.reportNumber,
    required this.title,
    required this.location,
    required this.submittedAt,
    required this.status,
    required this.isPotentialDuplicate,
    required this.coReporterCount,
    this.mediaUrls = const [],
    this.pointsAwarded = 0,
    this.category,
    this.severity,
    this.cleanupEffort,
    this.description,
  });

  final String id;
  final String reportNumber;
  final String title;
  /// Optional extra context (subtitle); may be null from API.
  final String? description;
  final String location;
  final DateTime submittedAt;
  final ApiReportStatus status;
  final bool isPotentialDuplicate;
  final int coReporterCount;
  final List<String> mediaUrls;
  final int pointsAwarded;
  final ReportCategory? category;
  final int? severity;
  final CleanupEffort? cleanupEffort;
}
