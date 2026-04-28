import 'package:chisto_mobile/features/home/data/api_site_engagement_http.dart';
import 'package:chisto_mobile/features/home/domain/repositories/site_engagement_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

/// [SiteEngagementRepository] backed by [ApiSiteEngagementHttp].
class ApiSiteEngagementRepository implements SiteEngagementRepository {
  ApiSiteEngagementRepository(this._http);

  final ApiSiteEngagementHttp _http;

  @override
  Future<EngagementSnapshot> upvoteSite(String id) => _http.upvoteSite(id);

  @override
  Future<EngagementSnapshot> removeSiteUpvote(String id) =>
      _http.removeSiteUpvote(id);

  @override
  Future<EngagementSnapshot> saveSite(String id) => _http.saveSite(id);

  @override
  Future<EngagementSnapshot> unsaveSite(String id) => _http.unsaveSite(id);

  @override
  Future<EngagementSnapshot> shareSite(String id, {String channel = 'native'}) =>
      _http.shareSite(id, channel: channel);

  @override
  Future<SiteShareLinkPayload> issueSiteShareLink(String id, {String channel = 'native'}) =>
      _http.issueSiteShareLink(id, channel: channel);

  @override
  Future<bool> ingestSiteShareOpen({
    required String token,
    required String eventType,
    String source = 'APP',
  }) =>
      _http.ingestSiteShareOpen(token: token, eventType: eventType, source: source);
}
