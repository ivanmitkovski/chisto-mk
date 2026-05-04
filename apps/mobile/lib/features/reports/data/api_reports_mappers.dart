import 'package:chisto_mobile/features/reports/data/api_reports_json_wrappers.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';

ReportListItem reportListItemFromApiJson(Map<String, dynamic> json) {
  final String statusStr = json['status'] as String? ?? 'NEW';
  final ApiReportStatus status = parseApiReportStatusFromApi(statusStr);
  final String submittedAtStr = json['submittedAt'] as String? ?? '';
  final DateTime submittedAt = DateTime.tryParse(submittedAtStr) ?? DateTime.now();
  final List<String> mediaUrls = reportMediaUrlsFromJson(json);
  final String? categoryStr = json['category'] as String?;
  final num? severityNum = json['severity'] as num?;
  final String? cleanupStr = json['cleanupEffort'] as String?;
  final ReportViewerRole viewerRole =
      (json['viewerRole'] as String?) == 'co_reporter'
      ? ReportViewerRole.coReporter
      : ReportViewerRole.primary;
  return ReportListItem(
    id: json['id'] as String? ?? '',
    reportNumber: json['reportNumber'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    location: json['location'] as String? ?? '',
    submittedAt: submittedAt,
    status: status,
    isPotentialDuplicate: json['isPotentialDuplicate'] as bool? ?? false,
    coReporterCount: (json['coReporterCount'] as num?)?.toInt() ?? 0,
    mediaUrls: mediaUrls,
    pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
    category: ReportCategory.fromApiString(categoryStr),
    severity: severityNum?.toInt(),
    cleanupEffort: CleanupEffort.fromApiString(cleanupStr),
    viewerRole: viewerRole,
  );
}

ReportDetail reportDetailFromApiJson(Map<String, dynamic> json) {
  final String statusStr = json['status'] as String? ?? 'NEW';
  final ApiReportStatus status = parseApiReportStatusFromApi(statusStr);
  final String submittedAtStr = json['submittedAt'] as String? ?? '';
  final DateTime submittedAt = DateTime.tryParse(submittedAtStr) ?? DateTime.now();
  final Map<String, dynamic>? siteJson = json['site'] as Map<String, dynamic>?;
  final ReportDetailSite site = siteJson != null
      ? ReportDetailSite(
          id: siteJson['id'] as String? ?? '',
          latitude: (siteJson['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (siteJson['longitude'] as num?)?.toDouble() ?? 0,
          description: siteJson['description'] as String?,
          address: siteJson['address'] as String?,
        )
      : ReportDetailSite(id: '', latitude: 0, longitude: 0);
  final List<String> mediaUrls = reportMediaUrlsFromJson(json);
  final List<dynamic> coList = json['coReporterNames'] as List<dynamic>? ?? <dynamic>[];
  final List<String> coReporterNames = coList.whereType<String>().map<String>((String s) => s).toList();
  final String? categoryStr = json['category'] as String?;
  final num? severityNum = json['severity'] as num?;
  final String? cleanupStr = json['cleanupEffort'] as String?;
  final ReportViewerRole viewerRole =
      (json['viewerRole'] as String?) == 'co_reporter'
      ? ReportViewerRole.coReporter
      : ReportViewerRole.primary;
  return ReportDetail(
    id: json['id'] as String? ?? '',
    reportNumber: json['reportNumber'] as String? ?? '',
    status: status,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    mediaUrls: mediaUrls,
    submittedAt: submittedAt,
    site: site,
    location: json['location'] as String? ?? '',
    reporterName: json['reporterName'] as String?,
    coReporterNames: coReporterNames,
    pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
    category: ReportCategory.fromApiString(categoryStr),
    severity: severityNum?.toInt(),
    cleanupEffort: CleanupEffort.fromApiString(cleanupStr),
    viewerRole: viewerRole,
  );
}
