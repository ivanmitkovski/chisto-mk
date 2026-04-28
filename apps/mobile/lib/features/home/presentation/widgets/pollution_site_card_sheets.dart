import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_comment_mapping.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments_bottom_sheet.dart';
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
}) async {
  trackPollutionFeedCardEvent(
    site.id,
    eventType: PollutionFeedCardEventType.commentOpen,
    sessionId: feedSessionId,
  );

  Future<List<Comment>> loadComments(String sort) async {
    final SiteCommentsResult result =
        await ServiceLocator.instance.sitesRepository.getSiteComments(
      site.id,
      sort: sort,
    );
    if (context.mounted) {
      ref
          .read(siteEngagementNotifierProvider(site.id).notifier)
          .setCommentCount(result.total);
    }
    return result.items.map(commentFromSiteCommentItem).toList();
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

  final DraggableScrollableController sheetController =
      DraggableScrollableController();
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
      final bool keyboardOpen =
          MediaQuery.of(sheetContext).viewInsets.bottom > 0;
      if (keyboardOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!sheetController.isAttached) return;
          if (sheetController.size >= 0.94) return;
          sheetController.animateTo(
            0.95,
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
          );
        });
      }
      return DraggableScrollableSheet(
        controller: sheetController,
        expand: false,
        initialChildSize: keyboardOpen ? 0.95 : 0.74,
        minChildSize: keyboardOpen ? 0.95 : 0.56,
        maxChildSize: 0.95,
        snap: !keyboardOpen,
        snapSizes: keyboardOpen ? null : const <double>[0.74, 0.95],
        builder: (BuildContext _, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusPill),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CommentsBottomSheet(
              siteId: site.id,
              comments: commentsForSheet,
              siteTitle: site.title,
              scrollController: scrollController,
              onCommentsCountChanged: (int count) {
                if (!sheetContext.mounted) return;
                ref
                    .read(siteEngagementNotifierProvider(site.id).notifier)
                    .setCommentCount(count);
              },
              onCommentsChanged: (List<Comment> comments) {
                if (!sheetContext.mounted) return;
                onSessionCommentsChanged(comments);
              },
              onLoadMoreDirectReplies:
                  (String parentId, int page, String sort) async {
                final SiteCommentsResult result =
                    await ServiceLocator.instance.sitesRepository
                        .getSiteComments(
                  site.id,
                  parentId: parentId,
                  page: page,
                  limit: 20,
                  sort: sort,
                );
                return result.items.map(commentFromSiteCommentItem).toList();
              },
              onCommentSubmitted: (String text, String? parentId) {
                return ServiceLocator.instance.sitesRepository
                    .createSiteComment(site.id, text, parentId: parentId)
                    .then(commentFromSiteCommentItem);
              },
              onCommentEdited: (String commentId, String body) {
                return ServiceLocator.instance.sitesRepository
                    .updateSiteComment(site.id, commentId, body);
              },
              onCommentDeleted: (String commentId) {
                return ServiceLocator.instance.sitesRepository
                    .deleteSiteComment(site.id, commentId);
              },
              onCommentLikeToggled: (String commentId, bool shouldLike) {
                return shouldLike
                    ? ServiceLocator.instance.sitesRepository
                        .likeSiteComment(site.id, commentId)
                        .then((_) {})
                    : ServiceLocator.instance.sitesRepository
                        .unlikeSiteComment(site.id, commentId)
                        .then((_) {});
              },
            ),
          );
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
