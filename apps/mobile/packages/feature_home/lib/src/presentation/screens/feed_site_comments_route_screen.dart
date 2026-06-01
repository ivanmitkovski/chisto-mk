import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/providers/feed_providers.dart';
import 'package:feature_home/src/presentation/providers/site_comments_route_notifier.dart';
import 'package:feature_home/src/presentation/providers/site_engagement_provider.dart';
import 'package:feature_home/src/presentation/utils/site_comment_mapping.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_route_loading_skeleton.dart';
import 'package:feature_home/src/presentation/widgets/comments_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen comments for a site (shell route: `/feed/:siteId/comments`).
class FeedSiteCommentsRouteScreen extends ConsumerStatefulWidget {
  const FeedSiteCommentsRouteScreen({
    super.key,
    required this.siteId,
    this.highlightCommentId,
    this.highlightActorUserId,
  });

  final String siteId;
  final String? highlightCommentId;
  final String? highlightActorUserId;

  @override
  ConsumerState<FeedSiteCommentsRouteScreen> createState() =>
      _FeedSiteCommentsRouteScreenState();
}

class _FeedSiteCommentsRouteScreenState
    extends ConsumerState<FeedSiteCommentsRouteScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onCommentsScrollNearEnd);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onCommentsScrollNearEnd);
    _scrollController.dispose();
    super.dispose();
  }

  void _onCommentsScrollNearEnd() {
    if (!mounted) {
      return;
    }
    final SiteCommentsRouteState st = ref.read(
      siteCommentsRouteNotifierProvider(widget.siteId),
    );
    if (!st.hasMoreComments ||
        st.loadingMoreComments ||
        !_scrollController.hasClients) {
      return;
    }
    final ScrollPosition pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 480) {
      return;
    }
    unawaited(_runLoadMore());
  }

  Future<void> _runLoadMore() async {
    final SiteCommentsLoadMoreResult result = await ref
        .read(siteCommentsRouteNotifierProvider(widget.siteId).notifier)
        .loadMoreComments();
    if (!mounted || result != SiteCommentsLoadMoreResult.failed) {
      return;
    }
    AppSnack.show(
      context,
      message: context.l10n.feedCommentsLoadMoreFailedSnack,
      type: AppSnackType.warning,
    );
  }

  String? _issueMessage(SiteCommentsRouteIssue issue) {
    switch (issue) {
      case SiteCommentsRouteIssue.none:
        return null;
      case SiteCommentsRouteIssue.siteNotFound:
        return context.l10n.feedSiteNotFoundMessage;
      case SiteCommentsRouteIssue.bootstrapFailed:
        return context.l10n.siteCardCommentsLoadFailedSnack;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SiteCommentsRouteState st = ref.watch(
      siteCommentsRouteNotifierProvider(widget.siteId),
    );
    final SitesRepository sitesRepository = ref.read(sitesRepositoryProvider);
    final String currentUserId = ref.read(authStateProvider).userId ?? '';
    final String? errorMessage = st.loading ? null : _issueMessage(st.issue);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          st.site?.title ?? context.l10n.feedSiteCommentsAppBarFallback,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: st.loading
          ? const ColoredBox(
              color: AppColors.panelBackground,
              child: CommentsRouteLoadingSkeleton(),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    AppButton.primary(
                      label: context.l10n.commonTryAgain,
                      onPressed: () {
                        unawaited(
                          ref
                              .read(
                                siteCommentsRouteNotifierProvider(
                                  widget.siteId,
                                ).notifier,
                              )
                              .retryBootstrap(),
                        );
                      },
                      expand: false,
                    ),
                  ],
                ),
              ),
            )
          : ColoredBox(
              color: AppColors.panelBackground,
              child: SafeArea(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    try {
                      await ref
                          .read(
                            siteCommentsRouteNotifierProvider(
                              widget.siteId,
                            ).notifier,
                          )
                          .refreshComments();
                    } catch (_) {
                      if (!context.mounted) return;
                      AppSnack.show(
                        context,
                        message:
                            context.l10n.commentsPrefetchCouldNotRefreshSnack,
                        type: AppSnackType.warning,
                      );
                    }
                  },
                  child: CommentsBottomSheet(
                    siteId: widget.siteId,
                    comments: st.comments,
                    siteTitle: st.site?.title,
                    scrollController: _scrollController,
                    highlightCommentId: widget.highlightCommentId,
                    highlightActorUserId: widget.highlightActorUserId,
                    isLoadingMoreComments: st.loadingMoreComments,
                    onCommentsCountChanged: (int count) {
                      ref
                          .read(
                            siteEngagementNotifierProvider(
                              widget.siteId,
                            ).notifier,
                          )
                          .setCommentCount(count);
                      ref
                          .read(feedSitesNotifierProvider.notifier)
                          .patchSiteCommentsCount(widget.siteId, count);
                    },
                    onCommentsChanged: (List<Comment> next) {
                      ref
                          .read(
                            siteCommentsRouteNotifierProvider(
                              widget.siteId,
                            ).notifier,
                          )
                          .replaceComments(next);
                    },
                    onLoadMoreDirectReplies:
                        (String parentId, int page, String sort) async {
                          final SiteCommentsResult result =
                              await sitesRepository.getSiteComments(
                                widget.siteId,
                                parentId: parentId,
                                page: page,
                                limit: 20,
                                sort: sort,
                              );
                          return result.items
                              .map(
                                (SiteCommentItem item) =>
                                    commentFromSiteCommentItem(
                                      currentUserId,
                                      item,
                                    ),
                              )
                              .toList();
                        },
                    onCommentSubmitted: (String text, String? parentId) {
                      return sitesRepository
                          .createSiteComment(
                            widget.siteId,
                            text,
                            parentId: parentId,
                          )
                          .then(
                            (SiteCommentItem item) =>
                                commentFromSiteCommentItem(currentUserId, item),
                          );
                    },
                    onCommentEdited: (String commentId, String body) {
                      return sitesRepository.updateSiteComment(
                        widget.siteId,
                        commentId,
                        body,
                      );
                    },
                    onCommentDeleted: (String commentId) {
                      return sitesRepository.deleteSiteComment(
                        widget.siteId,
                        commentId,
                      );
                    },
                    onCommentLikeToggled: (String commentId, bool shouldLike) {
                      return shouldLike
                          ? sitesRepository
                                .likeSiteComment(widget.siteId, commentId)
                                .then((_) {})
                          : sitesRepository
                                .unlikeSiteComment(widget.siteId, commentId)
                                .then((_) {});
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
