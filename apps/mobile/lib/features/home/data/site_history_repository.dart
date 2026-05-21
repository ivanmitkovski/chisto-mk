import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';

class SiteHistoryRepository {
  SiteHistoryRepository(this._client);

  final ApiClient _client;

  Future<SiteHistoryPage> fetchHistory(
    String siteId, {
    int limit = 30,
    String? beforeId,
  }) async {
    final String trimmedId = siteId.trim();
    if (trimmedId.isEmpty) {
      throw AppError.validation(message: 'Site id is required');
    }
    final StringBuffer query = StringBuffer('limit=$limit');
    if (beforeId != null && beforeId.isNotEmpty) {
      query.write('&beforeId=$beforeId');
    }
    final response = await _client.get('/sites/$trimmedId/history?$query');
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown(cause: 'Missing site history response body');
    }
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(_entryFromJson)
        .toList(growable: false);
    final String? nextBeforeId = json['nextBeforeId'] as String?;
    return SiteHistoryPage(items: items, nextBeforeId: nextBeforeId);
  }

  SiteHistoryEntry _entryFromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? actor = json['actor'] as Map<String, dynamic>?;
    return SiteHistoryEntry(
      id: json['id'] as String,
      kind: siteHistoryEntryKindFromApi(json['kind'] as String? ?? ''),
      occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String?,
      reportId: json['reportId'] as String?,
      cleanupEventId: json['cleanupEventId'] as String?,
      actorDisplayName: actor?['displayName'] as String?,
      actorRole: actor?['role'] as String?,
      note: json['note'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
