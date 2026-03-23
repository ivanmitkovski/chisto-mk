import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// API report status for list/detail display.
enum ApiReportStatus {
  new_('Under review'),
  inReview('Under review'),
  approved('Approved'),
  deleted('Declined');

  const ApiReportStatus(this.label);
  final String label;
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
  });

  final String id;
  final String reportNumber;
  final String title;
  final String location;
  final DateTime submittedAt;
  final ApiReportStatus status;
  final bool isPotentialDuplicate;
  final int coReporterCount;
  final List<String> mediaUrls;
  final int pointsAwarded;
  final ReportCategory? category;
  final int? severity;
}
