import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/presentation/utils/comment_meta_formatting.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comments_motion.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// One comment row in a site thread (feed sheet or full-screen route).
class CommentListTile extends StatelessWidget {
  const CommentListTile({
    super.key,
    required this.comment,
    required this.depth,
    required this.isBusy,
    required this.isLiking,
    required this.isEditing,
    required this.isDeleting,
    required this.onLikeTap,
    this.onOpenMenu,
    required this.onReplyTap,
    required this.hasReplies,
    required this.repliesExpanded,
    this.onToggleReplies,
    this.showLoadMoreReplies = false,
    this.onLoadMoreReplies,
    this.isLoadingMoreReplies = false,
  });

  final Comment comment;
  final int depth;
  final bool isBusy;
  final bool isLiking;
  final bool isEditing;
  final bool isDeleting;
  final VoidCallback onLikeTap;
  final VoidCallback? onOpenMenu;
  final VoidCallback onReplyTap;
  final bool hasReplies;
  final bool repliesExpanded;
  final VoidCallback? onToggleReplies;
  final bool showLoadMoreReplies;
  final VoidCallback? onLoadMoreReplies;
  final bool isLoadingMoreReplies;

  @override
  Widget build(BuildContext context) {
    final bool isLikedByMe = comment.isLikedByMe ?? false;
    final bool showThreadGuide = depth >= 1 && depth <= 2;

    final TextStyle nameStyle = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary);
    final TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimary);

    final double indent = (depth * 18).clamp(0, 54).toDouble();
    final String metaText = formatCommentMetaSubtitle(
      context.l10n,
      comment.createdAt,
      DateTime.now(),
      isDeleting: isDeleting,
      isEditing: isEditing,
      likeCount: comment.likeCount,
    );
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: indent),
            AppAvatar(
              name: comment.authorName,
              imageUrl: comment.authorAvatarUrl,
              size: 36,
              fontSize: 14,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DecoratedBox(
                decoration: showThreadGuide
                    ? BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            width: 2,
                          ),
                        ),
                      )
                    : const BoxDecoration(),
                child: Padding(
                  padding: EdgeInsets.only(left: showThreadGuide ? 10 : 0),
                  child: AnimatedOpacity(
                    duration: CommentsMotion.tileBusyOpacityDuration(context),
                    opacity: isBusy
                        ? CommentsMotion.tileBusyOpacityValue(context)
                        : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RichText(
                          text: TextSpan(
                            style: textStyle,
                            children: <TextSpan>[
                              TextSpan(
                                text: '${comment.authorName} ',
                                style: nameStyle,
                              ),
                              TextSpan(text: comment.text),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metaText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          button: true,
                          label: context.l10n.commentsReplyToSemantic(
                            comment.authorName,
                          ),
                          child: GestureDetector(
                            onTap: onReplyTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                context.l10n.commentsReplyButton,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        if (hasReplies && onToggleReplies != null)
                          Semantics(
                            button: true,
                            label: repliesExpanded
                                ? context.l10n.commentsSemanticHideReplies(
                                    comment.authorName,
                                  )
                                : context.l10n.commentsSemanticViewReplies(
                                    comment.authorName,
                                  ),
                            child: GestureDetector(
                              onTap: onToggleReplies,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      repliesExpanded
                                          ? context.l10n.commentsHideReplies
                                          : context.l10n.commentsViewReplies,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 2),
                                    AnimatedRotation(
                                      turns: repliesExpanded ? 0.5 : 0,
                                      duration:
                                          CommentsMotion.replyChevronRotationDuration(
                                            context,
                                          ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (showLoadMoreReplies &&
                            onLoadMoreReplies != null &&
                            comment.repliesCount > comment.replies.length)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: TextButton(
                              onPressed: isLoadingMoreReplies
                                  ? null
                                  : onLoadMoreReplies,
                              child: isLoadingMoreReplies
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      context.l10n.commentsLoadMoreReplies(
                                        comment.repliesCount -
                                            comment.replies.length,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (onOpenMenu != null)
                  IconButton(
                    onPressed: isBusy ? null : onOpenMenu,
                    splashRadius: 14,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    visualDensity: VisualDensity.compact,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                Semantics(
                  button: true,
                  label: isLikedByMe
                      ? context.l10n.commentsUnlikeTooltip
                      : context.l10n.commentsLikeTooltip,
                  child: IconButton(
                    onPressed: isBusy && !isLiking ? null : onLikeTap,
                    splashRadius: 16,
                    icon: AnimatedSwitcher(
                      duration: CommentsMotion.likeIconSwitcherDuration(
                        context,
                      ),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) =>
                              ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                      child: isLiking
                          ? const SizedBox(
                              key: ValueKey<String>('liking'),
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                              ),
                            )
                          : Icon(
                              isLikedByMe
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey<bool>(isLikedByMe),
                              size: 18,
                              color: isLikedByMe
                                  ? AppColors.accentDanger
                                  : AppColors.textMuted,
                            ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: isLikedByMe
                        ? context.l10n.commentsUnlikeTooltip
                        : context.l10n.commentsLikeTooltip,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
