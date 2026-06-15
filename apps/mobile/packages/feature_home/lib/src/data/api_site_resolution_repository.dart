import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_home/src/domain/repositories/site_resolution_repository.dart';
import 'package:feature_reports/feature_reports.dart';

class ApiSiteResolutionRepository implements SiteResolutionRepository {
  ApiSiteResolutionRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<List<String>> uploadResolutionPhotos(
    String siteId,
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) {
      return <String>[];
    }
    final ReportMultipartPartsResult multipart =
        reportMultipartPartsForLocalPaths(filePaths);
    if (multipart.parts.isEmpty) {
      throw AppError.validation(message: 'No readable photo files to upload.');
    }
    final ApiResponse response = await _client.multipartPostWithRetry(
      '/sites/$siteId/resolutions/upload',
      files: multipart.parts,
      timeout: kReportMediaUploadTimeout,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    return urlsFromReportsUploadResponse(json);
  }

  @override
  Future<SiteResolutionSubmitResult> submitSiteResolution({
    required String siteId,
    required List<String> mediaUrls,
    String? note,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'mediaUrls': mediaUrls};
    final String? trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      body['note'] = trimmedNote;
    }
    final ApiResponse response = await _client.post(
      '/sites/$siteId/resolutions',
      body: body,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final Map<String, dynamic> payload =
        safeAsStringKeyedMap(json['data']) ?? json;
    return SiteResolutionSubmitResult(
      id: payload['id'] as String? ?? '',
      siteId: payload['siteId'] as String? ?? siteId,
      status: payload['status'] as String? ?? 'PENDING',
    );
  }

  @override
  Future<CleanupEvidenceListResult> getCleanupEvidence(
    String siteId, {
    int page = 1,
    int limit = 24,
    RequestCancellationToken? cancellation,
  }) async {
    final ApiResponse response = await _client.get(
      '/sites/$siteId/cleanup-evidence?page=$page&limit=$limit',
      cancellation: cancellation,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final List<dynamic> data = safeAsList(json['data']) ?? <dynamic>[];
    final Map<String, dynamic>? meta = safeAsStringKeyedMap(json['meta']);
    final List<CleanupEvidenceItem> items = data
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> row) => CleanupEvidenceItem(
            id: row['id'] as String? ?? '',
            url: row['url'] as String? ?? '',
            source: row['source'] as String? ?? 'RESOLUTION',
            createdAt: row['createdAt'] as String? ?? '',
            caption: row['caption'] as String?,
            submitterDisplayLabel:
                safeAsStringKeyedMap(row['submitter'])?['displayLabel']
                    as String?,
            resolutionId: row['resolutionId'] as String?,
            cleanupEventId: row['cleanupEventId'] as String?,
          ),
        )
        .toList(growable: false);
    return CleanupEvidenceListResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  Future<SiteResolutionListResult> listSiteResolutions(
    String siteId, {
    int page = 1,
    int limit = 20,
    RequestCancellationToken? cancellation,
  }) async {
    final ApiResponse response = await _client.get(
      '/sites/$siteId/resolutions?page=$page&limit=$limit',
      cancellation: cancellation,
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    final List<dynamic> data = safeAsList(json['data']) ?? <dynamic>[];
    final Map<String, dynamic>? meta = safeAsStringKeyedMap(json['meta']);
    final List<SiteResolutionListItem> items = data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> row) {
          final Map<String, dynamic>? submitter =
              safeAsStringKeyedMap(row['submitter']);
          final List<dynamic> mediaRaw =
              safeAsList(row['mediaUrls']) ?? <dynamic>[];
          return SiteResolutionListItem(
            id: row['id'] as String? ?? '',
            siteId: row['siteId'] as String? ?? siteId,
            status: row['status'] as String? ?? 'PENDING',
            mediaUrls: mediaRaw.whereType<String>().toList(growable: false),
            createdAt: DateTime.tryParse(row['createdAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            isSelf: submitter?['isSelf'] == true,
            note: row['note'] as String?,
          );
        })
        .toList(growable: false);
    return SiteResolutionListResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      limit: (meta?['limit'] as num?)?.toInt() ?? limit,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
