import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/home/data/api_feed_analytics_repository.dart';
import 'package:chisto_mobile/features/home/data/api_feed_sites_repository.dart';
import 'package:chisto_mobile/features/home/data/api_site_comments_repository.dart';
import 'package:chisto_mobile/features/home/data/api_site_engagement_http.dart';
import 'package:chisto_mobile/features/home/data/api_site_engagement_repository.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

/// Composes [ApiFeedSitesRepository], engagement HTTP, comments, and feed analytics.
class ApiSitesRepository implements SitesRepository {
  ApiSitesRepository({
    required ApiClient client,
    AuthState? authState,
  }) {
    _feed = ApiFeedSitesRepository(client: client, authState: authState);
    _analytics = ApiFeedAnalyticsRepository(
      client: client,
      clearFeedCaches: _feed.clearAllCaches,
    );
    _engagementHttp = ApiSiteEngagementHttp(
      client: client,
      clearFeedCaches: _feed.clearAllCaches,
      rememberLocalUpvote: _feed.rememberLocalUpvote,
      forgetLocalUpvote: _feed.forgetLocalUpvote,
    );
    _engagement = ApiSiteEngagementRepository(_engagementHttp);
    _comments = ApiSiteCommentsRepository(client);
  }

  late final ApiFeedSitesRepository _feed;
  late final ApiFeedAnalyticsRepository _analytics;
  late final ApiSiteEngagementHttp _engagementHttp;
  late final ApiSiteEngagementRepository _engagement;
  late final ApiSiteCommentsRepository _comments;

  @override
  Future<SitesListResult> getSites({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? status,
    int page = 1,
    int limit = 20,
    String sort = 'hybrid',
    String mode = 'for_you',
    bool explain = false,
    String? cursor,
  }) =>
      _feed.getSites(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        status: status,
        page: page,
        limit: limit,
        sort: sort,
        mode: mode,
        explain: explain,
        cursor: cursor,
      );

  @override
  Future<MapSitesResult> getSitesForMap({
    required double latitude,
    required double longitude,
    double radiusKm = 80,
    int limit = 200,
    double? minLatitude,
    double? maxLatitude,
    double? minLongitude,
    double? maxLongitude,
    String mapDetail = SitesRepository.mapDetailLite,
  }) =>
      _feed.getSitesForMap(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
        minLatitude: minLatitude,
        maxLatitude: maxLatitude,
        minLongitude: minLongitude,
        maxLongitude: maxLongitude,
        mapDetail: mapDetail,
      );

  @override
  Future<PollutionSite?> getSiteById(String id) => _feed.getSiteById(id);

  @override
  Future<EngagementSnapshot> upvoteSite(String id) =>
      _engagement.upvoteSite(id);

  @override
  Future<EngagementSnapshot> removeSiteUpvote(String id) =>
      _engagement.removeSiteUpvote(id);

  @override
  Future<EngagementSnapshot> saveSite(String id) => _engagement.saveSite(id);

  @override
  Future<EngagementSnapshot> unsaveSite(String id) =>
      _engagement.unsaveSite(id);

  @override
  Future<EngagementSnapshot> shareSite(
    String id, {
    String channel = 'native',
  }) =>
      _engagement.shareSite(id, channel: channel);

  @override
  Future<SiteShareLinkPayload> issueSiteShareLink(
    String id, {
    String channel = 'native',
  }) =>
      _engagement.issueSiteShareLink(id, channel: channel);

  @override
  Future<bool> ingestSiteShareOpen({
    required String token,
    required String eventType,
    String source = 'APP',
  }) =>
      _engagement.ingestSiteShareOpen(
        token: token,
        eventType: eventType,
        source: source,
      );

  @override
  Future<SiteCommentsResult> getSiteComments(
    String id, {
    int page = 1,
    int limit = 20,
    String sort = 'top',
    String? parentId,
  }) =>
      _comments.getSiteComments(
        id,
        page: page,
        limit: limit,
        sort: sort,
        parentId: parentId,
      );

  @override
  Future<SiteUpvotesResult> getSiteUpvotes(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      _comments.getSiteUpvotes(id, page: page, limit: limit);

  @override
  Future<SiteCommentItem> createSiteComment(
    String id,
    String body, {
    String? parentId,
  }) =>
      _comments.createSiteComment(id, body, parentId: parentId);

  @override
  Future<void> updateSiteComment(
    String siteId,
    String commentId,
    String body,
  ) =>
      _comments.updateSiteComment(siteId, commentId, body);

  @override
  Future<void> deleteSiteComment(String siteId, String commentId) =>
      _comments.deleteSiteComment(siteId, commentId);

  @override
  Future<SiteCommentLikeSnapshot> likeSiteComment(
    String siteId,
    String commentId,
  ) =>
      _comments.likeSiteComment(siteId, commentId);

  @override
  Future<SiteCommentLikeSnapshot> unlikeSiteComment(
    String siteId,
    String commentId,
  ) =>
      _comments.unlikeSiteComment(siteId, commentId);

  @override
  Future<SiteMediaResult> getSiteMedia(
    String id, {
    int page = 1,
    int limit = 24,
  }) =>
      _comments.getSiteMedia(id, page: page, limit: limit);

  @override
  Future<void> trackFeedEvent(
    String siteId, {
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) =>
      _analytics.trackFeedEvent(
        siteId,
        eventType: eventType,
        sessionId: sessionId,
        metadata: metadata,
      );

  @override
  Future<void> submitFeedFeedback(
    String siteId, {
    required String feedbackType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) =>
      _analytics.submitFeedFeedback(
        siteId,
        feedbackType: feedbackType,
        sessionId: sessionId,
        metadata: metadata,
      );
}
