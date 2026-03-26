import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';

/// Site info within a report detail.
class ReportDetailSite {
  const ReportDetailSite({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String? description;
  final String? address;
}

/// Full report detail from GET /reports/:id (citizen view).
class ReportDetail {
  const ReportDetail({
    required this.id,
    required this.reportNumber,
    required this.status,
    required this.title,
    required this.description,
    required this.mediaUrls,
    required this.submittedAt,
    required this.site,
    required this.location,
    this.reporterName,
    this.coReporterNames = const <String>[],
    this.pointsAwarded = 0,
    this.category,
    this.severity,
    this.cleanupEffort,
  });

  final String id;
  final String reportNumber;
  final ApiReportStatus status;
  final String title;
  final String? description;
  final List<String> mediaUrls;
  final DateTime submittedAt;
  final ReportDetailSite site;
  final String location;
  final String? reporterName;
  final List<String> coReporterNames;
  final int pointsAwarded;
  final ReportCategory? category;
  final int? severity;
  final CleanupEffort? cleanupEffort;
}
