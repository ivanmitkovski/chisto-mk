import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/debug/chisto_submit_debug_log.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_reports/src/data/api_reports_json_wrappers.dart';
import 'package:feature_reports/src/data/api_reports_mappers.dart';
import 'package:feature_reports/src/data/api_reports_multipart.dart';
import 'package:feature_reports/src/data/report_multipart_parts_result.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/domain/models/report_photo_upload_outcome.dart';
import 'package:feature_reports/src/domain/models/report_submit_points_breakdown.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/models/reports_list_response.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';

class ApiReportsRepository implements ReportsApiRepository {
  ApiReportsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<ReportPhotoUploadOutcome> uploadPhotos(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      return const ReportPhotoUploadOutcome(urls: <String>[]);
    }
    final ReportMultipartPartsResult multipart =
        reportMultipartPartsForLocalPaths(filePaths);
    if (multipart.parts.isEmpty) {
      throw AppError.validation(message: 'No readable photo files to upload.');
    }
    final ApiResponse response = await _client.multipartPostWithRetry(
      '/reports/upload',
      files: multipart.parts,
      timeout: kReportMediaUploadTimeout,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final List<String> urls = urlsFromReportsUploadResponse(json);
    if (urls.isEmpty) {
      throw AppError.validation(message: 'Server returned no image URLs.');
    }
    return ReportPhotoUploadOutcome(
      urls: urls,
      skippedPhotoCount: multipart.skippedCount,
    );
  }

  @override
  Future<void> uploadReportMedia(
    String reportId,
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return;
    final ReportMultipartPartsResult multipart =
        reportMultipartPartsForLocalPaths(filePaths);
    if (multipart.parts.isEmpty) {
      throw AppError.validation(message: 'No readable photo files to upload.');
    }
    await _client.multipartPostWithRetry(
      '/reports/$reportId/media',
      files: multipart.parts,
      timeout: kReportMediaUploadTimeout,
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
    final Map<String, String>? headers =
        idempotencyKey != null && idempotencyKey.trim().isNotEmpty
        ? <String, String>{'Idempotency-Key': idempotencyKey.trim()}
        : null;
    final ApiResponse response = await _client.post(
      '/reports',
      body: body,
      headers: headers,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      final String? raw = response.body;
      final String snippet = raw == null
          ? '<null>'
          : (raw.length > 256 ? '${raw.substring(0, 256)}...' : raw);
      chistoSubmitDebugLog(
        'submitReport empty/non-JSON status=${response.statusCode} body=$snippet',
      );
      AppLog.warn(
        'submitReport: empty/non-JSON body status=${response.statusCode} '
        'body=$snippet',
        category: 'reports_api',
      );
      throw AppError.unknown();
    }
    final Map<String, dynamic> payload = createReportSubmitPayload(json);
    final String reportId = payload['reportId'] as String? ?? '';
    if (reportId.isEmpty) {
      throw AppError.validation(
        message: 'Server response missing report id; cannot upload photos.',
      );
    }
    final List<dynamic>? rawBreakdown = safeAsList(payload['pointsBreakdown']);
    List<ReportSubmitPointsBreakdownLine>? breakdown;
    if (rawBreakdown != null && rawBreakdown.isNotEmpty) {
      breakdown = rawBreakdown
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> m) => ReportSubmitPointsBreakdownLine(
              code: (m['code'] as String?)?.trim() ?? '',
              points: (m['points'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((ReportSubmitPointsBreakdownLine e) => e.code.isNotEmpty)
          .toList();
      if (breakdown.isEmpty) {
        breakdown = null;
      }
    }
    return ReportSubmitResult(
      reportId: reportId,
      reportNumber: payload['reportNumber'] as String?,
      siteId: payload['siteId'] as String? ?? '',
      isNewSite: payload['isNewSite'] as bool? ?? false,
      pointsAwarded: (payload['pointsAwarded'] as num?)?.toInt() ?? 0,
      pointsBreakdown: breakdown,
      submittedMediaUrls: const <String>[],
    );
  }

  @override
  Future<ReportsListResponse> getMyReports({
    int page = 1,
    int limit = 20,
    RequestCancellationToken? cancellation,
  }) async {
    chistoReportsBreadcrumb(
      'reports_api',
      'getMyReports start',
      data: <String, Object?>{'page': page, 'limit': limit},
    );
    try {
      final ApiResponse response = await _client.get(
        '/reports/me?page=$page&limit=$limit',
        cancellation: cancellation,
      );
      final Map<String, dynamic>? json = response.json;
      if (json == null) throw AppError.unknown();
      final List<dynamic> data = safeAsList(json['data']) ?? <dynamic>[];
      final List<ReportListItem> items = data
          .whereType<Map<String, dynamic>>()
          .map<ReportListItem>(reportListItemFromApiJson)
          .toList();
      chistoReportsBreadcrumb(
        'reports_api',
        'getMyReports ok',
        data: <String, Object?>{
          'status': response.statusCode,
          'count': items.length,
        },
      );
      return ReportsListResponse(
        data: items,
        total: (json['total'] as num?)?.toInt() ?? items.length,
        page: (json['page'] as num?)?.toInt() ?? page,
        limit: (json['limit'] as num?)?.toInt() ?? limit,
      );
    } catch (e, _) {
      chistoReportsBreadcrumb(
        'reports_api',
        'getMyReports error',
        data: <String, Object?>{'type': e.runtimeType.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<ReportDetail> getReportById(
    String id, {
    RequestCancellationToken? cancellation,
  }) async {
    final ApiResponse response = await _client.get(
      '/reports/$id',
      cancellation: cancellation,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return reportDetailFromApiJson(singleResourceReportPayload(json));
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
      nextRefillAtMs: (json['nextRefillAtMs'] as num?)?.toInt(),
      unlockHint:
          json['unlockHint'] as String? ??
          'Join and verify attendance, or create an eco action to unlock more reports.',
    );
  }
}
