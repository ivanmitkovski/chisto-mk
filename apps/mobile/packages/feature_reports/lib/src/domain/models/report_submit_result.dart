import 'package:feature_reports/src/domain/models/report_submit_points_breakdown.dart';

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
    this.uploadPhotosSkippedCount = 0,
    this.uploadCompressionFallbackCount = 0,
  });

  final String reportId;
  final String? reportNumber;
  final String siteId;
  final bool isNewSite;
  final int pointsAwarded;
  final List<ReportSubmitPointsBreakdownLine>? pointsBreakdown;

  /// URLs persisted by the submit pipeline (outbox); not returned by POST /reports JSON.
  final List<String> submittedMediaUrls;

  /// Non-fatal: local photos skipped before upload (>12MB or missing).
  final int uploadPhotosSkippedCount;

  /// Non-fatal: JPEG compression failed; original bytes were used.
  final int uploadCompressionFallbackCount;

  bool get hasUploadWarnings =>
      uploadPhotosSkippedCount > 0 || uploadCompressionFallbackCount > 0;

  ReportSubmitResult copyWith({
    String? reportId,
    String? reportNumber,
    String? siteId,
    bool? isNewSite,
    int? pointsAwarded,
    List<ReportSubmitPointsBreakdownLine>? pointsBreakdown,
    List<String>? submittedMediaUrls,
    int? uploadPhotosSkippedCount,
    int? uploadCompressionFallbackCount,
  }) {
    return ReportSubmitResult(
      reportId: reportId ?? this.reportId,
      reportNumber: reportNumber ?? this.reportNumber,
      siteId: siteId ?? this.siteId,
      isNewSite: isNewSite ?? this.isNewSite,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      pointsBreakdown: pointsBreakdown ?? this.pointsBreakdown,
      submittedMediaUrls: submittedMediaUrls ?? this.submittedMediaUrls,
      uploadPhotosSkippedCount:
          uploadPhotosSkippedCount ?? this.uploadPhotosSkippedCount,
      uploadCompressionFallbackCount:
          uploadCompressionFallbackCount ?? this.uploadCompressionFallbackCount,
    );
  }
}
