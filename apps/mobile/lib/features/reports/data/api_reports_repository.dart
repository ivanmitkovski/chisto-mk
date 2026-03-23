import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

class ApiReportsRepository implements ReportsApiRepository {
  ApiReportsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    if (filePaths.isEmpty) return <String>[];
    final ApiResponse response =
        await _client.postMultipart('/reports/upload', filePaths);
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> urls = json['urls'] as List<dynamic>? ?? <dynamic>[];
    return urls
        .whereType<String>()
        .map<String>((String u) => u)
        .toList();
  }

  @override
  Future<void> uploadReportMedia(String reportId, List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    await _client.postMultipart('/reports/$reportId/media', filePaths);
  }

  @override
  Future<ReportSubmitResult> submitReport({
    required double latitude,
    required double longitude,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body['mediaUrls'] = mediaUrls;
    }
    if (category != null && category.isNotEmpty) {
      body['category'] = category;
    }
    if (severity != null && severity >= 1 && severity <= 5) {
      body['severity'] = severity;
    }
    final ApiResponse response = await _client.post('/reports', body: body);
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return ReportSubmitResult(
      reportId: json['reportId'] as String? ?? '',
      reportNumber: json['reportNumber'] as String?,
      siteId: json['siteId'] as String? ?? '',
      isNewSite: json['isNewSite'] as bool? ?? false,
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<ReportsListResponse> getMyReports({
    int page = 1,
    int limit = 20,
  }) async {
    final ApiResponse response = await _client.get(
      '/reports/me?page=$page&limit=$limit',
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<ReportListItem> items = data
        .whereType<Map<String, dynamic>>()
        .map<ReportListItem>(_reportListItemFromJson)
        .toList();
    return ReportsListResponse(
      data: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? page,
      limit: (json['limit'] as num?)?.toInt() ?? limit,
    );
  }

  @override
  Future<ReportDetail> getReportById(String id) async {
    final ApiResponse response = await _client.get('/reports/$id');
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return _reportDetailFromJson(json);
  }

  ReportListItem _reportListItemFromJson(Map<String, dynamic> json) {
    final String statusStr = json['status'] as String? ?? 'NEW';
    final ApiReportStatus status = _parseApiStatus(statusStr);
    final String submittedAtStr = json['submittedAt'] as String? ?? '';
    final DateTime submittedAt = DateTime.tryParse(submittedAtStr) ?? DateTime.now();
    final List<dynamic> mediaList = json['mediaUrls'] as List<dynamic>? ?? <dynamic>[];
    final List<String> mediaUrls =
        mediaList.whereType<String>().map<String>((String s) => s).toList();
    final String? categoryStr = json['category'] as String?;
    final num? severityNum = json['severity'] as num?;
    return ReportListItem(
      id: json['id'] as String? ?? '',
      reportNumber: json['reportNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      submittedAt: submittedAt,
      status: status,
      isPotentialDuplicate: json['isPotentialDuplicate'] as bool? ?? false,
      coReporterCount: (json['coReporterCount'] as num?)?.toInt() ?? 0,
      mediaUrls: mediaUrls,
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
      category: ReportCategory.fromApiString(categoryStr),
      severity: severityNum != null ? severityNum.toInt() : null,
    );
  }

  ReportDetail _reportDetailFromJson(Map<String, dynamic> json) {
    final String statusStr = json['status'] as String? ?? 'NEW';
    final ApiReportStatus status = _parseApiStatus(statusStr);
    final String submittedAtStr = json['submittedAt'] as String? ?? '';
    final DateTime submittedAt = DateTime.tryParse(submittedAtStr) ?? DateTime.now();
    final Map<String, dynamic>? siteJson =
        json['site'] as Map<String, dynamic>?;
    final ReportDetailSite site = siteJson != null
        ? ReportDetailSite(
            id: siteJson['id'] as String? ?? '',
            latitude: (siteJson['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (siteJson['longitude'] as num?)?.toDouble() ?? 0,
            description: siteJson['description'] as String?,
          )
        : ReportDetailSite(id: '', latitude: 0, longitude: 0);
    final List<dynamic> mediaList = json['mediaUrls'] as List<dynamic>? ?? <dynamic>[];
    final List<String> mediaUrls =
        mediaList.whereType<String>().map<String>((String s) => s).toList();
    final List<dynamic> coList = json['coReporterNames'] as List<dynamic>? ?? <dynamic>[];
    final List<String> coReporterNames =
        coList.whereType<String>().map<String>((String s) => s).toList();
    final String? categoryStr = json['category'] as String?;
    final num? severityNum = json['severity'] as num?;
    return ReportDetail(
      id: json['id'] as String? ?? '',
      reportNumber: json['reportNumber'] as String? ?? '',
      status: status,
      description: json['description'] as String?,
      mediaUrls: mediaUrls,
      submittedAt: submittedAt,
      site: site,
      location: json['location'] as String? ?? '',
      reporterName: json['reporterName'] as String?,
      coReporterNames: coReporterNames,
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
      category: ReportCategory.fromApiString(categoryStr),
      severity: severityNum != null ? severityNum.toInt() : null,
    );
  }

  ApiReportStatus _parseApiStatus(String s) {
    switch (s.toUpperCase()) {
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
}
