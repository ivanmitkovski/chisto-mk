import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/civic_actor_display.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_avatar.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/presentation/utils/comment_meta_formatting.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_motion.dart';
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
    final String authorLabel = civicActorDisplayLabel(
      context.l10n,
      displayName: comment.authorName,
      isDeleted: comment.authorIsDeleted,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isLikedByMe = comment.isLikedByMe ?? false;
    final bool showThreadGuide = depth >= 1 && depth <= 2;

    final TextStyle nameStyle = AppTypography.cardTitle(
      textTheme,
    ).copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary);
    final TextStyle textStyle = AppTypography.cardSubtitle(
      textTheme,
    ).copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimary);

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
              name: authorLabel,
              imageUrl: comment.authorIsDeleted
                  ? null
                  : comment.authorAvatarUrl,
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
                  padding: EdgeInsets.only(
                    left: showThreadGuide ? AppSpacing.radius10 : 0,
                  ),
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
                              TextSpan(text: '$authorLabel ', style: nameStyle),
                              TextSpan(text: comment.text),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metaText,
                          style: AppTypography.cardSubtitle(
                            textTheme,
                          ).copyWith(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          button: true,
                          label: context.l10n.commentsReplyToSemantic(
                            authorLabel,
                          ),
                          child: GestureDetector(
                            onTap: onReplyTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.radiusHandle,
                              ),
                              child: Text(
                                context.l10n.commentsReplyButton,
                                style: AppTypography.chipLabel(textTheme)
                                    .copyWith(
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
                                    authorLabel,
                                  )
                                : context.l10n.commentsSemanticViewReplies(
                                    authorLabel,
                                  ),
                            child: GestureDetector(
                              onTap: onToggleReplies,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.insetTight,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      repliesExpanded
                                          ? context.l10n.commentsHideReplies
                                          : context.l10n.commentsViewReplies,
                                      style: AppTypography.chipLabel(textTheme)
                                          .copyWith(
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
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: AppButton.text(
                              label: context.l10n.commentsLoadMoreReplies(
                                comment.repliesCount - comment.replies.length,
                              ),
                              onPressed: onLoadMoreReplies,
                              enabled: !isLoadingMoreReplies,
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
                    splashColor: AppColors.transparent,
                    highlightColor: AppColors.transparent,
                    hoverColor: AppColors.transparent,
                    focusColor: AppColors.transparent,
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
                              child: AppLoadingIndicator(
                                size: AppLoadingIndicatorSize.sm,
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
                    splashColor: AppColors.transparent,
                    highlightColor: AppColors.transparent,
                    hoverColor: AppColors.transparent,
                    focusColor: AppColors.transparent,
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
