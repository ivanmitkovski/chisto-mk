import 'package:chisto_mobile/features/reports/domain/models/report_submit_points_breakdown.dart';

/// Result of successfully submitting a report.
class ReportSubmitResult {
  const ReportSubmitResult({
    required this.reportId,
    this.reportNumber,
    required this.siteId,
    required this.isNewSite,
    required this.pointsAwarded,
    this.pointsBreakdown,
    this.submittedMediaUrls = const <String>[],
  });

  final String reportId;
  final String? reportNumber;
  final String siteId;
  final bool isNewSite;
  final int pointsAwarded;
  final List<ReportSubmitPointsBreakdownLine>? pointsBreakdown;

  /// URLs persisted by the submit pipeline (outbox); not returned by POST /reports JSON.
  final List<String> submittedMediaUrls;

  ReportSubmitResult copyWith({
    String? reportId,
    String? reportNumber,
    String? siteId,
    bool? isNewSite,
    int? pointsAwarded,
    List<ReportSubmitPointsBreakdownLine>? pointsBreakdown,
    List<String>? submittedMediaUrls,
  }) {
    return ReportSubmitResult(
      reportId: reportId ?? this.reportId,
      reportNumber: reportNumber ?? this.reportNumber,
      siteId: siteId ?? this.siteId,
      isNewSite: isNewSite ?? this.isNewSite,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      pointsBreakdown: pointsBreakdown ?? this.pointsBreakdown,
      submittedMediaUrls: submittedMediaUrls ?? this.submittedMediaUrls,
    );
  }
}
