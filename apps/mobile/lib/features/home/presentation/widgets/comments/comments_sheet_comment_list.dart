import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comment_list_tile.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comments_motion.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comments_thread_empty_state.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comments_thread_flatten.dart';
import 'package:flutter/material.dart';

/// Scrollable thread for [CommentsBottomSheet].
class CommentsSheetCommentList extends StatelessWidget {
  const CommentsSheetCommentList({
    super.key,
    required this.comments,
    required this.expandedReplyIds,
    required this.scrollController,
    required this.expandedKeyToken,
    required this.isCommentBusy,
    required this.isCommentLiking,
    required this.isCommentEditing,
    required this.isCommentDeleting,
    required this.onLikeTap,
    required this.onOpenMenu,
    required this.onReplyTap,
    required this.hasExpandableThread,
    required this.onToggleReplies,
    required this.showLoadMoreReplies,
    required this.onLoadMoreReplies,
    required this.isLoadingMoreReplies,
  });

  final List<Comment> comments;
  final Set<String> expandedReplyIds;
  final ScrollController scrollController;
  final String expandedKeyToken;
  final bool Function(String id) isCommentBusy;
  final bool Function(String id) isCommentLiking;
  final bool Function(String id) isCommentEditing;
  final bool Function(String id) isCommentDeleting;
  final void Function(String commentId) onLikeTap;
  final void Function(Comment comment)? onOpenMenu;
  final void Function(Comment comment) onReplyTap;
  final bool Function(Comment c) hasExpandableThread;
  final void Function(Comment c) onToggleReplies;
  final bool Function(Comment c) showLoadMoreReplies;
  final void Function(Comment c)? onLoadMoreReplies;
  final bool Function(Comment c) isLoadingMoreReplies;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const CommentsThreadEmptyState();
    }
    final List<FlattenedComment> flattened = flattenCommentThread(
      comments,
      expandedReplyIds,
    );
    return AnimatedSwitcher(
      duration: CommentsMotion.listAnimatedSwitcherDuration(context),
      child: ListView.separated(
        key: ValueKey<String>('$expandedKeyToken-${flattened.length}'),
        controller: scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        itemCount: flattened.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final FlattenedComment item = flattened[index];
          final Comment comment = item.comment;
          return CommentListTile(
            comment: comment,
            depth: item.depth,
            isBusy: isCommentBusy(comment.id),
            isLiking: isCommentLiking(comment.id),
            isEditing: isCommentEditing(comment.id),
            isDeleting: isCommentDeleting(comment.id),
            onLikeTap: () => onLikeTap(comment.id),
            onOpenMenu: comment.isOwnedByMe && onOpenMenu != null
                ? () => onOpenMenu!(comment)
                : null,
            onReplyTap: () => onReplyTap(comment),
            hasReplies: hasExpandableThread(comment),
            repliesExpanded: expandedReplyIds.contains(comment.id),
            onToggleReplies: !hasExpandableThread(comment)
                ? null
                : () => onToggleReplies(comment),
            showLoadMoreReplies: showLoadMoreReplies(comment),
            onLoadMoreReplies:
                showLoadMoreReplies(comment) && onLoadMoreReplies != null
                ? () => onLoadMoreReplies!(comment)
                : null,
            isLoadingMoreReplies: isLoadingMoreReplies(comment),
          );
        },
      ),
    );
  }
}
