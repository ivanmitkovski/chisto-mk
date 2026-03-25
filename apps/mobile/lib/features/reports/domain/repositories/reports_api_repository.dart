import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';

/// Repository for reports API: upload, submit, list, detail.
abstract class ReportsApiRepository {
  /// Upload photos to S3; returns public URLs for use in submitReport.
  Future<List<String>> uploadPhotos(List<String> filePaths);

  /// Append photos to an existing report. Use after submitReport to avoid S3 orphans.
  Future<void> uploadReportMedia(String reportId, List<String> filePaths);

  /// Submit a report with location. Returns reportId, siteId, isNewSite, pointsAwarded.
  Future<ReportSubmitResult> submitReport({
    required double latitude,
    required double longitude,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
    String? address,
    String? cleanupEffort,
  });

  /// Paginated list of current user's reports.
  Future<ReportsListResponse> getMyReports({
    int page = 1,
    int limit = 20,
  });

  /// Full report detail for citizen (own report).
  Future<ReportDetail> getReportById(String id);

  /// Current reporting capacity policy state for preflight checks and UX hints.
  Future<ReportCapacity> getReportingCapacity();
}
