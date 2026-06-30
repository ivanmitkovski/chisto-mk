import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/utils/comment_input_validator.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_motion.dart';
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
    this.keyboardOverlaysSheet = false,
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

  /// When true (resizable modal), the keyboard overlays the sheet bottom.
  /// Lift the composer visually instead of growing layout with [viewInsets].
  final bool keyboardOverlaysSheet;

  /// When true, send is disabled and a small progress indicator is shown (new comment path).
  final bool isCommitting;
  final ValueChanged<String> onTextChanged;
  final Future<void> Function([String? raw]) onCommit;
  final VoidCallback onCancelEdit;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double keyboardInset = keyboardOverlaysSheet
        ? appSheetOverlayKeyboardInset(context)
        : mediaQuery.viewInsets.bottom;
    // Continuous in [keyboardInset] so the composer tracks the IME animation
    // frame-by-frame with no padding snap when the keyboard starts opening.
    final double restingPadding = AppSpacing.md + mediaQuery.padding.bottom;
    final double bottomPadding = keyboardOverlaysSheet
        ? math.max(AppSpacing.xs, restingPadding - keyboardInset)
        : math.max(restingPadding, keyboardInset + AppSpacing.xs);
    final bool showComposerBanner =
        editingCommentId != null || replyToCommentId != null;

    Widget bar = Padding(
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
              final int used = CommentInputValidator.normalizedLength(
                commentController.text,
              );
              const int maxLen = CommentInputValidator.maxBodyLength;
              if (used < maxLen - 100) {
                return const SizedBox.shrink();
              }
              final int remaining = (maxLen - used).clamp(0, maxLen);
              return Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Text(
                    context.l10n.commentsComposerCharsRemaining(remaining),
                    style: AppTypographySurfaces.homeCommentsComposerCounter(
                      Theme.of(context).textTheme,
                      color: used > maxLen - 50
                          ? AppColors.error
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
                child: DesignSystemTextField(
                  controller: commentController,
                  focusNode: commentFocusNode,
                  textAlignVertical: TextAlignVertical.center,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: CommentInputValidator.maxBodyLength,
                  buildCounter:
                      (
                        BuildContext context, {
                        required int currentLength,
                        required int? maxLength,
                        required bool isFocused,
                      }) => null,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onChanged: onTextChanged,
                  decoration: InputDecoration(
                    hintText: editingCommentId != null
                        ? context.l10n.commentsInputHintEdit
                        : (replyToCommentId == null
                              ? context.l10n.commentsInputHintAdd
                              : context.l10n.commentsInputHintReply),
                    hintStyle: AppTypography.cardSubtitle(
                      textTheme,
                    ).copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: AppColors.inputFill.withValues(alpha: 0.9),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.radius10,
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  style: AppTypographySurfaces.homeCommentsComposerField(
                    Theme.of(context).textTheme,
                    mentionActive:
                        replyToCommentId != null &&
                        commentController.text.trim().startsWith(
                          '@${replyToAuthor ?? ''}',
                        ),
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
                    borderRadius: AppRadii.circle,
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
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.radiusSm),
                              child: AppLoadingIndicator(
                                size: AppLoadingIndicatorSize.sm,
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

    if (keyboardOverlaysSheet) {
      // Keep this wrapper mounted even while the keyboard is closed: toggling
      // it mid IME animation re-parents (remounts) the focused TextField,
      // which closes the input connection and dismisses the keyboard.
      bar = Transform.translate(offset: Offset(0, -keyboardInset), child: bar);
    }

    return bar;
  }
}
