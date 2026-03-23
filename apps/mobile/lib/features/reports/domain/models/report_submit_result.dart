/// Result of successfully submitting a report.
class ReportSubmitResult {
  const ReportSubmitResult({
    required this.reportId,
    this.reportNumber,
    required this.siteId,
    required this.isNewSite,
    required this.pointsAwarded,
  });

  final String reportId;
  final String? reportNumber;
  final String siteId;
  final bool isNewSite;
  final int pointsAwarded;
}
