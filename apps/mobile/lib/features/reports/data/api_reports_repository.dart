import 'dart:io';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

class ApiReportsRepository implements ReportsApiRepository {
  ApiReportsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  static const Duration _reportMediaUploadTimeout = Duration(seconds: 90);

  /// POST /reports may be wrapped as `{ data: { reportId, ... } }` by gateways.
  static Map<String, dynamic> _createReportSubmitPayload(Map<String, dynamic> json) {
    final Object? data = json['data'];
    if (data is Map<String, dynamic> && data['reportId'] != null) {
      return data;
    }
    return json;
  }

  /// Matches API upload validation: magic bytes are authoritative; `application/octet-stream` is allowed.
  static String _mimeTypeForReportUploadPath(String p) {
    final String lower = p.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  static String _uploadFileNameForPath(String path, int index) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'report_$index.png';
    if (lower.endsWith('.webp')) return 'report_$index.webp';
    return 'report_$index.jpg';
  }

  static List<MultipartFileData> _multipartPartsForLocalPaths(List<String> filePaths) {
    final List<MultipartFileData> parts = <MultipartFileData>[];
    int index = 0;
    for (final String path in filePaths) {
      final File f = File(path);
      if (!f.existsSync()) {
        continue;
      }
      final List<int> bytes = f.readAsBytesSync();
      if (bytes.isEmpty) {
        continue;
      }
      parts.add(
        MultipartFileData(
          field: 'files',
          bytes: bytes,
          fileName: _uploadFileNameForPath(path, index),
          mimeType: _mimeTypeForReportUploadPath(path),
        ),
      );
      index++;
    }
    return parts;
  }

  static List<String> _urlsFromUploadResponse(Map<String, dynamic> json) {
    Map<String, dynamic> map = json;
    final Object? data = json['data'];
    if (data is Map<String, dynamic> && data['urls'] != null) {
      map = data;
    }
    final List<dynamic> urls = map['urls'] as List<dynamic>? ?? <dynamic>[];
    return urls
        .whereType<String>()
        .map<String>((String u) => u.trim())
        .where((String u) => u.isNotEmpty)
        .toList();
  }

  /// Some gateways return `{ data: { ...entity } }` for single-resource GETs.
  static Map<String, dynamic> _singleResourcePayload(Map<String, dynamic> json) {
    final Object? data = json['data'];
    if (data is Map<String, dynamic> &&
        (data.containsKey('id') ||
            data.containsKey('mediaUrls') ||
            data.containsKey('title'))) {
      return data;
    }
    return json;
  }

  static String _normalizeMediaFetchUrl(String raw) {
    final String s = raw.trim();
    if (s.isEmpty) return s;
    if (s.startsWith('//')) {
      return 'https:$s';
    }
    return s;
  }

  static List<String> _mediaUrlsFromJson(Map<String, dynamic> json) {
    final Object? raw = json['mediaUrls'] ?? json['media_urls'];
    if (raw == null) {
      return <String>[];
    }
    final List<dynamic> mediaList =
        raw is List<dynamic> ? raw : <dynamic>[raw];
    final List<String> out = <String>[];
    for (final dynamic e in mediaList) {
      if (e is String) {
        final String n = _normalizeMediaFetchUrl(e);
        if (n.isNotEmpty) {
          out.add(n);
        }
      } else if (e is Map<String, dynamic>) {
        final Object? u = e['url'] ?? e['href'];
        if (u is String) {
          final String n = _normalizeMediaFetchUrl(u);
          if (n.isNotEmpty) {
            out.add(n);
          }
        }
      }
    }
    return out;
  }

  @override
  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    if (filePaths.isEmpty) return <String>[];
    final List<MultipartFileData> parts = _multipartPartsForLocalPaths(filePaths);
    if (parts.isEmpty) {
      throw AppError.validation(message: 'No readable photo files to upload.');
    }
    final ApiResponse response = await _client.multipartPostWithRetry(
      '/reports/upload',
      files: parts,
      timeout: _reportMediaUploadTimeout,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<String> urls = _urlsFromUploadResponse(json);
    if (urls.isEmpty) {
      throw AppError.validation(message: 'Server returned no image URLs.');
    }
    return urls;
  }

  @override
  Future<void> uploadReportMedia(String reportId, List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    final List<MultipartFileData> parts = _multipartPartsForLocalPaths(filePaths);
    if (parts.isEmpty) {
      throw AppError.validation(message: 'No readable photo files to upload.');
    }
    await _client.multipartPostWithRetry(
      '/reports/$reportId/media',
      files: parts,
      timeout: _reportMediaUploadTimeout,
    );
  }

  @override
  Future<ReportSubmitResult> submitReport({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
    String? address,
    String? cleanupEffort,
    String? idempotencyKey,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
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
    final String? trimmedAddress = address?.trim();
    if (trimmedAddress != null && trimmedAddress.isNotEmpty) {
      body['address'] = trimmedAddress;
    }
    if (cleanupEffort != null && cleanupEffort.isNotEmpty) {
      body['cleanupEffort'] = cleanupEffort;
    }
    final Map<String, String>? headers = idempotencyKey != null && idempotencyKey.trim().isNotEmpty
        ? <String, String>{'Idempotency-Key': idempotencyKey.trim()}
        : null;
    final ApiResponse response = await _client.post('/reports', body: body, headers: headers);
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final Map<String, dynamic> payload = _createReportSubmitPayload(json);
    final String reportId = payload['reportId'] as String? ?? '';
    if (reportId.isEmpty) {
      throw AppError.validation(
        message: 'Server response missing report id; cannot upload photos.',
      );
    }
    return ReportSubmitResult(
      reportId: reportId,
      reportNumber: payload['reportNumber'] as String?,
      siteId: payload['siteId'] as String? ?? '',
      isNewSite: payload['isNewSite'] as bool? ?? false,
      pointsAwarded: (payload['pointsAwarded'] as num?)?.toInt() ?? 0,
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
    return _reportDetailFromJson(_singleResourcePayload(json));
  }

  @override
  Future<ReportCapacity> getReportingCapacity() async {
    final ApiResponse response = await _client.get('/reports/capacity');
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();

    final String? nextAtStr =
        (json['nextEmergencyReportAvailableAt'] as String?)?.trim();
    return ReportCapacity(
      creditsAvailable: (json['creditsAvailable'] as num?)?.toInt() ?? 0,
      emergencyAvailable: json['emergencyAvailable'] as bool? ?? false,
      emergencyWindowDays: (json['emergencyWindowDays'] as num?)?.toInt() ?? 7,
      retryAfterSeconds: (json['retryAfterSeconds'] as num?)?.toInt(),
      nextEmergencyReportAvailableAt: nextAtStr != null && nextAtStr.isNotEmpty
          ? DateTime.tryParse(nextAtStr)?.toUtc()
          : null,
      unlockHint: json['unlockHint'] as String? ?? 'Join and verify attendance, or create an eco action to unlock more reports.',
    );
  }

  ReportListItem _reportListItemFromJson(Map<String, dynamic> json) {
    final String statusStr = json['status'] as String? ?? 'NEW';
    final ApiReportStatus status = _parseApiStatus(statusStr);
    final String submittedAtStr = json['submittedAt'] as String? ?? '';
    final DateTime submittedAt = DateTime.tryParse(submittedAtStr) ?? DateTime.now();
    final List<String> mediaUrls = _mediaUrlsFromJson(json);
    final String? categoryStr = json['category'] as String?;
    final num? severityNum = json['severity'] as num?;
    final String? cleanupStr = json['cleanupEffort'] as String?;
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
      severity: severityNum != null ? severityNum.toInt() : null,
      cleanupEffort: CleanupEffort.fromApiString(cleanupStr),
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
            address: siteJson['address'] as String?,
          )
        : ReportDetailSite(id: '', latitude: 0, longitude: 0);
    final List<String> mediaUrls = _mediaUrlsFromJson(json);
    final List<dynamic> coList = json['coReporterNames'] as List<dynamic>? ?? <dynamic>[];
    final List<String> coReporterNames =
        coList.whereType<String>().map<String>((String s) => s).toList();
    final String? categoryStr = json['category'] as String?;
    final num? severityNum = json['severity'] as num?;
    final String? cleanupStr = json['cleanupEffort'] as String?;
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
      severity: severityNum != null ? severityNum.toInt() : null,
      cleanupEffort: CleanupEffort.fromApiString(cleanupStr),
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
