import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

/// Minimal [SitesRepository] for widget tests — only [searchSitesForMap] is used.
class StubSitesRepository implements SitesRepository {
  StubSitesRepository({
    this.searchResponse = const SiteMapSearchResponse(items: <PollutionSite>[]),
  });

  final SiteMapSearchResponse searchResponse;

  @override
  Future<SiteMapSearchResponse> searchSitesForMap(
    SiteMapSearchRequest request,
  ) async =>
      searchResponse;

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
      throw UnimplementedError();

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
    double? zoom,
    String? status,
    bool includeArchived = false,
    bool prefetch = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<PollutionSite?> getSiteById(String id) async => null;

  @override
  Future<EngagementSnapshot> upvoteSite(String id) => throw UnimplementedError();

  @override
  Future<EngagementSnapshot> removeSiteUpvote(String id) =>
      throw UnimplementedError();

  @override
  Future<EngagementSnapshot> saveSite(String id) => throw UnimplementedError();

  @override
  Future<EngagementSnapshot> unsaveSite(String id) => throw UnimplementedError();

  @override
  Future<EngagementSnapshot> shareSite(
    String id, {
    String channel = 'native',
  }) =>
      throw UnimplementedError();

  @override
  Future<SiteShareLinkPayload> issueSiteShareLink(
    String id, {
    String channel = 'native',
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> ingestSiteShareOpen({
    required String token,
    required String eventType,
    String source = 'APP',
  }) =>
      throw UnimplementedError();

  @override
  Future<SiteCommentsResult> getSiteComments(
    String id, {
    int page = 1,
    int limit = 20,
    String sort = 'top',
    String? parentId,
  }) =>
      throw UnimplementedError();

  @override
  Future<SiteUpvotesResult> getSiteUpvotes(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<SiteCommentItem> createSiteComment(
    String id,
    String body, {
    String? parentId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateSiteComment(
    String siteId,
    String commentId,
    String body,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteSiteComment(String siteId, String commentId) =>
      throw UnimplementedError();

  @override
  Future<SiteCommentLikeSnapshot> likeSiteComment(
    String siteId,
    String commentId,
  ) =>
      throw UnimplementedError();

  @override
  Future<SiteCommentLikeSnapshot> unlikeSiteComment(
    String siteId,
    String commentId,
  ) =>
      throw UnimplementedError();

  @override
  Future<SiteMediaResult> getSiteMedia(
    String id, {
    int page = 1,
    int limit = 24,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> trackFeedEvent(
    String siteId, {
    required String eventType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> submitFeedFeedback(
    String siteId, {
    required String feedbackType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) =>
      throw UnimplementedError();
}
