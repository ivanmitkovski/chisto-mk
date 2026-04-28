import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

abstract class SiteCommentsRepository {
  Future<SiteCommentsResult> getSiteComments(
    String id, {
    int page = 1,
    int limit = 20,
    String sort = 'top',
    String? parentId,
  });

  Future<SiteUpvotesResult> getSiteUpvotes(
    String id, {
    int page = 1,
    int limit = 20,
  });

  Future<SiteCommentItem> createSiteComment(
    String id,
    String body, {
    String? parentId,
  });

  Future<void> updateSiteComment(String siteId, String commentId, String body);
  Future<void> deleteSiteComment(String siteId, String commentId);
  Future<SiteCommentLikeSnapshot> likeSiteComment(String siteId, String commentId);
  Future<SiteCommentLikeSnapshot> unlikeSiteComment(
    String siteId,
    String commentId,
  );

  Future<SiteMediaResult> getSiteMedia(
    String id, {
    int page = 1,
    int limit = 24,
  });
}
