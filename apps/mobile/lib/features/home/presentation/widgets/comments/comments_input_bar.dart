import 'dart:async';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/presentation/utils/comment_input_validator.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments/comments_motion.dart';
import 'package:flutter/material.dart';

/// Sticky composer for site comments (reply / edit banners + field + send).
class CommentsInputBar extends StatelessWidget {
  const CommentsInputBar({
    super.key,
    required this.commentController,
    required this.commentFocusNode,
    required this.editingCommentId,
    required this.replyToCommentId,
    required this.replyToAuthor,
    required this.canPost,
    this.isCommitting = false,
    required this.onTextChanged,
    required this.onCommit,
    required this.onCancelEdit,
    required this.onCancelReply,
  });

  final TextEditingController commentController;
  final FocusNode commentFocusNode;
  final String? editingCommentId;
  final String? replyToCommentId;
  final String? replyToAuthor;
  final bool canPost;

  /// When true, send is disabled and a small progress indicator is shown (new comment path).
  final bool isCommitting;
  final ValueChanged<String> onTextChanged;
  final Future<void> Function([String? raw]) onCommit;
  final VoidCallback onCancelEdit;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final double bottomPadding = keyboardOpen
        ? mediaQuery.viewInsets.bottom + AppSpacing.xs
        : AppSpacing.md + mediaQuery.padding.bottom;
    final bool showComposerBanner =
        editingCommentId != null || replyToCommentId != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        showComposerBanner ? AppSpacing.xs : AppSpacing.xxs,
        AppSpacing.lg,
        bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showComposerBanner) ...<Widget>[
            SizedBox(
              height: 20,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 36),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: CommentsMotion.composerBannerSwitcherDuration(
                        context,
                      ),
                      child: editingCommentId != null
                          ? Text(
                              context.l10n.commentsEditingBanner,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            )
                          : Text(
                              context.l10n.commentsReplyingToBanner(
                                replyToAuthor ??
                                    context.l10n.commentsReplyTargetFallback,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 36,
                    child: AnimatedSwitcher(
                      duration: CommentsMotion.composerBannerSwitcherDuration(
                        context,
                      ),
                      child: editingCommentId != null
                          ? Semantics(
                              button: true,
                              label: context.l10n.commentsCancelEditSemantic,
                              child: GestureDetector(
                                onTap: onCancelEdit,
                                child: const Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            )
                          : Semantics(
                              button: true,
                              label: context.l10n.commentsCancelReplySemantic,
                              child: GestureDetector(
                                onTap: onCancelReply,
                                child: const Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
          Builder(
            builder: (BuildContext context) {
              final int used = CommentInputValidator.normalizeBody(
                commentController.text,
              ).length;
              if (used < 1600) {
                return const SizedBox.shrink();
              }
              const int maxLen = 2000;
              final int remaining = (maxLen - used).clamp(0, maxLen);
              return Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Text(
                    context.l10n.commentsComposerCharsRemaining(remaining),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: used > 1950
                          ? AppColors.accentDanger
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.inputFill,
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: commentController,
                  focusNode: commentFocusNode,
                  textAlignVertical: TextAlignVertical.center,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onChanged: onTextChanged,
                  decoration: InputDecoration(
                    hintText: editingCommentId != null
                        ? context.l10n.commentsInputHintEdit
                        : (replyToCommentId == null
                              ? context.l10n.commentsInputHintAdd
                              : context.l10n.commentsInputHintReply),
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: AppColors.inputFill.withValues(alpha: 0.9),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        replyToCommentId != null &&
                            commentController.text.trim().startsWith(
                              '@${replyToAuthor ?? ''}',
                            )
                        ? AppColors.primaryDark
                        : null,
                    fontWeight:
                        replyToCommentId != null &&
                            commentController.text.trim().startsWith(
                              '@${replyToAuthor ?? ''}',
                            )
                        ? FontWeight.w600
                        : null,
                  ),
                  onSubmitted: (String value) => unawaited(onCommit(value)),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedOpacity(
                duration: CommentsMotion.sendButtonOpacityDuration(context),
                opacity: (canPost && !isCommitting)
                    ? 1
                    : CommentsMotion.sendButtonDisabledOpacity(context),
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: (canPost && !isCommitting)
                        ? () => unawaited(onCommit())
                        : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (canPost && !isCommitting)
                            ? AppColors.primaryDark
                            : AppColors.inputFill,
                        shape: BoxShape.circle,
                      ),
                      child: isCommitting
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnDark,
                              ),
                            )
                          : Icon(
                              editingCommentId == null
                                  ? Icons.arrow_upward_rounded
                                  : Icons.check_rounded,
                              size: 18,
                              color: (canPost && !isCommitting)
                                  ? AppColors.textOnDark
                                  : AppColors.textMuted,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
