import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

abstract class SiteEngagementRepository {
  Future<EngagementSnapshot> upvoteSite(String id);
  Future<EngagementSnapshot> removeSiteUpvote(String id);
  Future<EngagementSnapshot> saveSite(String id);
  Future<EngagementSnapshot> unsaveSite(String id);
  Future<EngagementSnapshot> shareSite(String id, {String channel = 'native'});
  Future<SiteShareLinkPayload> issueSiteShareLink(String id, {String channel = 'native'});
  Future<bool> ingestSiteShareOpen({
    required String token,
    required String eventType,
    String source = 'APP',
  });
}
