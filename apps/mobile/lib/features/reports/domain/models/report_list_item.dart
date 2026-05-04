import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// API report status for list/detail display.
enum ApiReportStatus { new_, inReview, approved, deleted }

/// How the current user relates to a row from GET /reports/me.
enum ReportViewerRole { primary, coReporter }

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
    this.viewerRole = ReportViewerRole.primary,
    this.isOptimistic = false,
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
  final ReportViewerRole viewerRole;

  /// True until SSE `report_created` reconciles this row with the server list.
  final bool isOptimistic;

  ReportListItem copyWith({
    String? id,
    String? reportNumber,
    String? title,
    String? location,
    DateTime? submittedAt,
    ApiReportStatus? status,
    bool? isPotentialDuplicate,
    int? coReporterCount,
    List<String>? mediaUrls,
    int? pointsAwarded,
    ReportCategory? category,
    int? severity,
    CleanupEffort? cleanupEffort,
    String? description,
    ReportViewerRole? viewerRole,
    bool? isOptimistic,
  }) {
    return ReportListItem(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      title: title ?? this.title,
      location: location ?? this.location,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      isPotentialDuplicate: isPotentialDuplicate ?? this.isPotentialDuplicate,
      coReporterCount: coReporterCount ?? this.coReporterCount,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      cleanupEffort: cleanupEffort ?? this.cleanupEffort,
      description: description ?? this.description,
      viewerRole: viewerRole ?? this.viewerRole,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }
}

/// Parses API [Report.status] strings into [ApiReportStatus] for list/detail.
ApiReportStatus parseApiReportStatusFromApi(String raw) {
  switch (raw.toUpperCase()) {
    case 'NEW':
      return ApiReportStatus.new_;
    case 'IN_REVIEW':
      return ApiReportStatus.inReview;
    case 'APPROVED':
      return ApiReportStatus.approved;
    case 'DELETED':
      return ApiReportStatus.deleted;
    default:
      return ApiReportStatus.new_;
  }
}
