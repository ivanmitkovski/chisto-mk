import 'package:chisto_infrastructure/core/concurrency/single_flight.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/providers/feed_providers.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/providers/site_engagement_provider.dart';
import 'package:feature_home/src/presentation/utils/site_comment_mapping.dart';
import 'package:feature_home/src/presentation/utils/site_comments_engagement_count.dart';
import 'package:feature_home/src/presentation/widgets/comments_bottom_sheet.dart';
import 'package:feature_home/src/presentation/widgets/pollution_site_card_analytics.dart';
import 'package:feature_home/src/presentation/widgets/site_card/upvoters_sheet_content.dart';
import 'package:feature_home/src/presentation/widgets/site_comments_modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheets and server share tracking extracted from [PollutionSiteCard].
final SingleFlight<void> _pollutionSiteCardCommentsSheetFlight =
    SingleFlight<void>();

Future<void> openPollutionSiteCardCommentsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PollutionSite site,
  required List<Comment> initialSessionComments,
  required void Function(List<Comment> next) onSessionCommentsReplaced,
  required void Function(List<Comment> next) onSessionCommentsChanged,
  required String? feedSessionId,
  required String? feedVariant,
}) {
  return _pollutionSiteCardCommentsSheetFlight.run(() async {
    trackPollutionFeedCardEvent(
      site.id,
      eventType: PollutionFeedCardEventType.commentOpen,
      sessionId: feedSessionId,
      feedVariant: feedVariant,
    );

    final sitesRepository = ref.read(sitesRepositoryProvider);
    final String currentUserId = ref.read(authStateProvider).userId ?? '';

    Future<List<Comment>> loadComments(String sort) async {
      final SiteCommentsResult result = await sitesRepository.getSiteComments(
        site.id,
        sort: sort,
      );
      final List<Comment> mapped = result.items
          .map(
            (SiteCommentItem item) =>
                commentFromSiteCommentItem(currentUserId, item),
          )
          .toList();
      if (context.mounted) {
        final int n = commentCountForEngagementAfterFetch(
          result: result,
          mappedComments: mapped,
        );
        ref
            .read(siteEngagementNotifierProvider(site.id).notifier)
            .setCommentCount(n);
        ref
            .read(feedSitesNotifierProvider.notifier)
            .patchSiteCommentsCount(site.id, n);
      }
      return mapped;
    }

    List<Comment> commentsForSheet = List<Comment>.from(initialSessionComments);
    try {
      final List<Comment> comments = await loadComments('top');
      if (context.mounted) {
        onSessionCommentsReplaced(comments);
        commentsForSheet = comments;
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.siteCardCommentsLoadFailedSnack,
          type: AppSnackType.warning,
        );
      }
    }

    if (!context.mounted) return;

    await showPollutionSiteCommentsModalBottomSheet(
      context,
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            DraggableScrollableController sheetController,
            CommentsSheetSizeConfig sizeConfig,
          ) {
            return CommentsBottomSheet(
              siteId: site.id,
              comments: commentsForSheet,
              siteTitle: site.title,
              scrollController: scrollController,
              sheetController: sheetController,
              sheetSizeConfig: sizeConfig,
              onCommentsCountChanged: (int count) {
                if (!sheetContext.mounted) return;
                ref
                    .read(siteEngagementNotifierProvider(site.id).notifier)
                    .setCommentCount(count);
                ref
                    .read(feedSitesNotifierProvider.notifier)
                    .patchSiteCommentsCount(site.id, count);
              },
              onCommentsChanged: (List<Comment> comments) {
                if (!sheetContext.mounted) return;
                onSessionCommentsChanged(comments);
              },
              onLoadMoreDirectReplies:
                  (String parentId, int page, String sort) async {
                    final SiteCommentsResult result = await sitesRepository
                        .getSiteComments(
                          site.id,
                          parentId: parentId,
                          page: page,
                          limit: 20,
                          sort: sort,
                        );
                    return result.items
                        .map(
                          (SiteCommentItem item) =>
                              commentFromSiteCommentItem(currentUserId, item),
                        )
                        .toList();
                  },
              onCommentSubmitted: (String text, String? parentId) {
                return sitesRepository
                    .createSiteComment(site.id, text, parentId: parentId)
                    .then(
                      (SiteCommentItem item) =>
                          commentFromSiteCommentItem(currentUserId, item),
                    );
              },
              onCommentEdited: (String commentId, String body) {
                return sitesRepository.updateSiteComment(
                  site.id,
                  commentId,
                  body,
                );
              },
              onCommentDeleted: (String commentId) {
                return sitesRepository.deleteSiteComment(site.id, commentId);
              },
              onCommentLikeToggled: (String commentId, bool shouldLike) {
                return shouldLike
                    ? sitesRepository
                          .likeSiteComment(site.id, commentId)
                          .then((_) {})
                    : sitesRepository
                          .unlikeSiteComment(site.id, commentId)
                          .then((_) {});
              },
            );
          },
    );
  });
}

Future<void> openPollutionSiteCardUpvotersSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String siteId,
  String? highlightUserId,
}) async {
  final int count = ref
      .read(siteEngagementNotifierProvider(siteId))
      .upvoteCount
      .clamp(0, 999);
  final bool openingFromNotification =
      highlightUserId != null && highlightUserId.trim().isNotEmpty;
  if (count == 0 && !openingFromNotification) {
    AppSnack.show(
      context,
      message: context.l10n.siteDetailNoUpvotesSnack,
      type: AppSnackType.info,
    );
    return;
  }

  await AppBottomSheet.showResizable<void>(
    context: context,
    sizeConfig: const AppSheetSizeConfig(
      minSize: 0.5,
      maxSize: 0.95,
      snapSizes: <double>[0.68, 0.95],
      initialSize: 0.68,
    ),
    builder:
        (
          BuildContext sheetContext,
          ScrollController scrollController,
          DraggableScrollableController sheetController,
          AppSheetSizeConfig sizeConfig,
        ) {
          return UpvotersSheetContent(
            siteId: siteId,
            scrollController: scrollController,
            highlightUserId: highlightUserId,
            sheetController: sheetController,
            sizeConfig: sizeConfig,
          );
        },
  );
}
