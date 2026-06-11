import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/domain/repositories/site_history_repository_port.dart';

class SiteHistoryRepository implements SiteHistoryRepositoryPort {
  SiteHistoryRepository(this._client);

  final ApiClient _client;

  @override
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
    final List<dynamic> rawItems = safeAsList(json['items']) ?? <dynamic>[];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(_entryFromJson)
        .toList(growable: false);
    final String? nextBeforeId = json['nextBeforeId'] as String?;
    return SiteHistoryPage(
      items: items,
      nextBeforeId: nextBeforeId,
      summary: _summaryFromJson(safeAsStringKeyedMap(json['summary'])),
    );
  }

  SiteHistorySummary? _summaryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final String? currentStatus = json['currentStatus'] as String?;
    final String? firstActivityAt = json['firstActivityAt'] as String?;
    final String? lastActivityAt = json['lastActivityAt'] as String?;
    if (currentStatus == null ||
        firstActivityAt == null ||
        lastActivityAt == null) {
      return null;
    }
    return SiteHistorySummary(
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
      cleanupCount: (json['cleanupCount'] as num?)?.toInt() ?? 0,
      currentStatus: currentStatus,
      firstActivityAt: DateTime.parse(firstActivityAt).toLocal(),
      lastActivityAt: DateTime.parse(lastActivityAt).toLocal(),
    );
  }

  SiteHistoryEntry _entryFromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? actor = safeAsStringKeyedMap(json['actor']);
    return SiteHistoryEntry(
      id: json['id'] as String,
      kind: siteHistoryEntryKindFromApi(json['kind'] as String? ?? ''),
      occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String?,
      reportId: json['reportId'] as String?,
      cleanupEventId: json['cleanupEventId'] as String?,
      actorDisplayName: actor?['displayName'] as String?,
      actorIsDeleted: actor?['isDeleted'] as bool? ?? false,
      actorRole: actor?['role'] as String?,
      note: json['note'] as String?,
      metadata: safeAsStringKeyedMap(json['metadata']),
    );
  }
}
