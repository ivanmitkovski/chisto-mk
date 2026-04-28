import 'dart:async';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

/// POST/DELETE engagement endpoints may return a bare object or `{ "data": { ... } }`.
Map<String, dynamic>? _engagementSnapshotJsonRoot(Map<String, dynamic>? json) {
  if (json == null) return null;
  final Object? data = json['data'];
  if (data is Map<String, dynamic>) {
    if (data.containsKey('upvotesCount') ||
        data.containsKey('isUpvotedByMe') ||
        data.containsKey('is_upvoted_by_me')) {
      return data;
    }
  }
  return json;
}

bool _jsonTruthy(Object? value) {
  if (value == true) return true;
  if (value == false || value == null) return false;
  if (value is num) return value != 0;
  if (value is String) {
    final String t = value.trim().toLowerCase();
    return t == 'true' || t == '1' || t == 'yes';
  }
  return false;
}

bool _jsonBoolField(Map<String, dynamic> json, String camel, String snake) {
  return _jsonTruthy(json[camel]) || _jsonTruthy(json[snake]);
}

EngagementSnapshot engagementSnapshotFromJson(Map<String, dynamic>? json) {
  final Map<String, dynamic>? root = _engagementSnapshotJsonRoot(json);
  if (root == null) {
    throw AppError.unknown();
  }
  return EngagementSnapshot(
    siteId: root['siteId'] as String? ?? root['site_id'] as String? ?? '',
    upvotesCount: (root['upvotesCount'] as num?)?.toInt() ??
        (root['upvotes_count'] as num?)?.toInt() ??
        0,
    commentsCount: (root['commentsCount'] as num?)?.toInt() ??
        (root['comments_count'] as num?)?.toInt() ??
        0,
    savesCount: (root['savesCount'] as num?)?.toInt() ??
        (root['saves_count'] as num?)?.toInt() ??
        0,
    sharesCount: (root['sharesCount'] as num?)?.toInt() ??
        (root['shares_count'] as num?)?.toInt() ??
        0,
    isUpvotedByMe: _jsonBoolField(root, 'isUpvotedByMe', 'is_upvoted_by_me'),
    isSavedByMe: _jsonBoolField(root, 'isSavedByMe', 'is_saved_by_me'),
  );
}

SiteShareLinkPayload siteShareLinkFromJson(Map<String, dynamic>? json) {
  final Map<String, dynamic>? root = _engagementSnapshotJsonRoot(json) ?? json;
  if (root == null) {
    throw AppError.unknown();
  }
  final String expiresRaw = (root['expiresAt'] as String?) ??
      (root['expires_at'] as String?) ??
      DateTime.now().toUtc().toIso8601String();
  return SiteShareLinkPayload(
    siteId: root['siteId'] as String? ?? root['site_id'] as String? ?? '',
    cid: root['cid'] as String? ?? '',
    url: root['url'] as String? ?? '',
    token: root['token'] as String? ?? '',
    channel: root['channel'] as String? ?? 'native',
    expiresAt: DateTime.tryParse(expiresRaw)?.toUtc() ?? DateTime.now().toUtc(),
  );
}

/// Upvote / save / share mutations against `/sites/:id/*`.
class ApiSiteEngagementHttp {
  ApiSiteEngagementHttp({
    required ApiClient client,
    required Future<void> Function() clearFeedCaches,
    required Future<void> Function(String siteId) rememberLocalUpvote,
    required Future<void> Function(String siteId) forgetLocalUpvote,
  })  : _client = client,
        _clearFeedCaches = clearFeedCaches,
        _rememberLocalUpvote = rememberLocalUpvote,
        _forgetLocalUpvote = forgetLocalUpvote;

  final ApiClient _client;
  final Future<void> Function() _clearFeedCaches;
  final Future<void> Function(String siteId) _rememberLocalUpvote;
  final Future<void> Function(String siteId) _forgetLocalUpvote;

  Future<EngagementSnapshot> upvoteSite(String id) async {
    final ApiResponse response = await _client.post('/sites/$id/upvote');
    unawaited(_clearFeedCaches());
    final EngagementSnapshot snapshot =
        engagementSnapshotFromJson(response.json);
    if (snapshot.isUpvotedByMe) {
      await _rememberLocalUpvote(id);
    }
    return snapshot;
  }

  Future<EngagementSnapshot> removeSiteUpvote(String id) async {
    final ApiResponse response = await _client.delete('/sites/$id/upvote');
    unawaited(_clearFeedCaches());
    final EngagementSnapshot snapshot =
        engagementSnapshotFromJson(response.json);
    if (!snapshot.isUpvotedByMe) {
      await _forgetLocalUpvote(id);
    }
    return snapshot;
  }

  Future<EngagementSnapshot> saveSite(String id) async {
    final ApiResponse response = await _client.post('/sites/$id/save');
    unawaited(_clearFeedCaches());
    return engagementSnapshotFromJson(response.json);
  }

  Future<EngagementSnapshot> unsaveSite(String id) async {
    final ApiResponse response = await _client.delete('/sites/$id/save');
    unawaited(_clearFeedCaches());
    return engagementSnapshotFromJson(response.json);
  }

  Future<EngagementSnapshot> shareSite(
    String id, {
    String channel = 'native',
  }) async {
    final ApiResponse response = await _client.post(
      '/sites/$id/share',
      body: <String, dynamic>{'channel': channel},
    );
    unawaited(_clearFeedCaches());
    return engagementSnapshotFromJson(response.json);
  }

  Future<SiteShareLinkPayload> issueSiteShareLink(
    String id, {
    String channel = 'native',
  }) async {
    final ApiResponse response = await _client.post(
      '/sites/$id/share-link',
      body: <String, dynamic>{'channel': channel},
    );
    return siteShareLinkFromJson(response.json);
  }

  Future<bool> ingestSiteShareOpen({
    required String token,
    required String eventType,
    String source = 'APP',
  }) async {
    final ApiResponse response = await _client.post(
      '/sites/share-events/open',
      body: <String, dynamic>{
        'token': token,
        'eventType': eventType,
        'source': source,
      },
    );
    final Object? countedRaw = response.json?['counted'];
    if (countedRaw is bool) {
      return countedRaw;
    }
    return false;
  }
}
