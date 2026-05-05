import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/feed_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_comment_mapping.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_comments_engagement_count.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_comments_modal_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/pollution_site_card_analytics.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/upvoters_sheet_content.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Bottom sheets and server share tracking extracted from [PollutionSiteCard].
Future<void> openPollutionSiteCardCommentsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PollutionSite site,
  required List<Comment> initialSessionComments,
  required void Function(List<Comment> next) onSessionCommentsReplaced,
  required void Function(List<Comment> next) onSessionCommentsChanged,
  required String? feedSessionId,
  required String? feedVariant,
}) async {
  trackPollutionFeedCardEvent(
    site.id,
    eventType: PollutionFeedCardEventType.commentOpen,
    sessionId: feedSessionId,
    feedVariant: feedVariant,
  );

  final sitesRepository = ref.read(sitesRepositoryProvider);

  Future<List<Comment>> loadComments(String sort) async {
    final SiteCommentsResult result =
        await sitesRepository.getSiteComments(
      site.id,
      sort: sort,
    );
    final List<Comment> mapped =
        result.items.map(commentFromSiteCommentItem).toList();
    if (context.mounted) {
      final int n = commentCountForEngagementAfterFetch(
        result: result,
        mappedComments: mapped,
      );
      ref.read(siteEngagementNotifierProvider(site.id).notifier).setCommentCount(n);
      ref.read(feedSitesNotifierProvider.notifier).patchSiteCommentsCount(site.id, n);
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
    builder: (BuildContext sheetContext, ScrollController scrollController) {
      return CommentsBottomSheet(
        siteId: site.id,
        comments: commentsForSheet,
        siteTitle: site.title,
        scrollController: scrollController,
        onCommentsCountChanged: (int count) {
          if (!sheetContext.mounted) return;
          ref.read(siteEngagementNotifierProvider(site.id).notifier).setCommentCount(count);
          ref.read(feedSitesNotifierProvider.notifier).patchSiteCommentsCount(site.id, count);
        },
        onCommentsChanged: (List<Comment> comments) {
          if (!sheetContext.mounted) return;
          onSessionCommentsChanged(comments);
        },
        onLoadMoreDirectReplies:
            (String parentId, int page, String sort) async {
          final SiteCommentsResult result =
              await sitesRepository.getSiteComments(
            site.id,
            parentId: parentId,
            page: page,
            limit: 20,
            sort: sort,
          );
          return result.items.map(commentFromSiteCommentItem).toList();
        },
        onCommentSubmitted: (String text, String? parentId) {
          return sitesRepository
              .createSiteComment(site.id, text, parentId: parentId)
              .then(commentFromSiteCommentItem);
        },
        onCommentEdited: (String commentId, String body) {
          return sitesRepository.updateSiteComment(site.id, commentId, body);
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
}

Future<void> openPollutionSiteCardUpvotersSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String siteId,
}) async {
  final int count = ref
      .read(siteEngagementNotifierProvider(siteId))
      .upvoteCount
      .clamp(0, 999);
  if (count == 0) {
    AppSnack.show(
      context,
      message: context.l10n.siteDetailNoUpvotesSnack,
      type: AppSnackType.info,
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    useSafeArea: true,
    barrierColor: AppColors.overlay,
    backgroundColor: AppColors.transparent,
    builder: (BuildContext sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.68,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const <double>[0.68, 0.95],
        builder: (BuildContext _, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusPill),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: UpvotersSheetContent(
              siteId: siteId,
              scrollController: scrollController,
            ),
          );
        },
      );
    },
  );
}
