import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';

/// Instagram-style comments bottom sheet: header + scrollable list + sticky input bar.
///
/// This widget is intended to be used as the content of a modal bottom sheet.
class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    super.key,
    required this.comments,
    this.siteTitle,
    this.scrollController,
    this.onCommentsCountChanged,
    this.onCommentsChanged,
  });

  final List<Comment> comments;
  final String? siteTitle;
  final ScrollController? scrollController;
  final ValueChanged<int>? onCommentsCountChanged;
  final ValueChanged<List<Comment>>? onCommentsChanged;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late final List<Comment> _comments;
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;
  final ScrollController _fallbackScrollController = ScrollController();

  ScrollController get _listController =>
      widget.scrollController ?? _fallbackScrollController;

  bool get _ownsScrollController => widget.scrollController == null;
  bool get _canPost => _commentController.text.trim().isNotEmpty;

  int _safeLikeCount(Comment comment) =>
      (comment as dynamic).likeCount as int? ?? 0;

  bool _safeIsLikedByMe(Comment comment) =>
      (comment as dynamic).isLikedByMe as bool? ?? false;

  @override
  void initState() {
    super.initState();
    _comments = List<Comment>.from(widget.comments);
    _commentController = TextEditingController();
    _commentFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    if (_ownsScrollController) {
      _fallbackScrollController.dispose();
    }
    super.dispose();
  }

  void _submitComment([String? raw]) {
    final String text = (raw ?? _commentController.text).trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _comments.add(
        Comment(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          authorName: 'you',
          text: text,
          likeCount: 0,
          isLikedByMe: false,
        ),
      );
      _commentController.clear();
    });

    widget.onCommentsCountChanged?.call(_comments.length);
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
    FocusScope.of(context).requestFocus(_commentFocusNode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      _listController.animateTo(
        _listController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _toggleCommentLike(String commentId) {
    final int index = _comments.indexWhere((Comment c) => c.id == commentId);
    if (index < 0) return;

    final Comment current = _comments[index];
    final bool nextLiked = !_safeIsLikedByMe(current);
    final int nextLikeCount = nextLiked
        ? _safeLikeCount(current) + 1
        : (_safeLikeCount(current) - 1).clamp(0, 9999);

    HapticFeedback.selectionClick();
    setState(() {
      _comments[index] = current.copyWith(
        isLikedByMe: nextLiked,
        likeCount: nextLikeCount,
      );
    });
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // The bottom sheet route (useSafeArea: true) already handles the notch.
    // Here we just lay out the content.
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _buildHeader(context),
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No comments yet.\nBe the first to comment.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _listController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm, // small gap above the input bar
                  ),
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (BuildContext context, int index) {
                    final Comment comment = _comments[index];
                    return _CommentTile(
                      comment: comment,
                      onLikeTap: () => _toggleCommentLike(comment.id),
                    );
                  },
                ),
        ),
        _buildAddCommentBar(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    void _maybeClose() {
      Navigator.of(context).maybePop();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _maybeClose,
            onVerticalDragEnd: (DragEndDetails details) {
              // If the user flicks the header downward with enough velocity,
              // dismiss the sheet (Instagram / Apple-style).
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 200) {
                _maybeClose();
              }
            },
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Comments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (widget.siteTitle != null && widget.siteTitle!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              widget.siteTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }

  Widget _buildAddCommentBar(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    // When the keyboard is open the sheet has already been lifted by viewInsets,
    // so we keep the bar nearly glued to the keyboard with a tiny gap.
    // When the keyboard is closed we add comfortable padding above the home indicator.
    final double bottomPadding =
        keyboardOpen
            ? mediaQuery.viewInsets.bottom + 8
            : AppSpacing.md + mediaQuery.padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        bottomPadding,
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.inputFill,
            child: Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              textAlignVertical: TextAlignVertical.center,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.inputFill.withValues(alpha: 0.9),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onSubmitted: (String value) => _submitComment(value),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _canPost ? 1 : 0.45,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _canPost ? () => _submitComment() : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _canPost
                        ? AppColors.primaryDark
                        : AppColors.inputFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: _canPost ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onLikeTap,
  });

  final Comment comment;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    final int likeCount = (comment as dynamic).likeCount as int? ?? 0;
    final bool isLikedByMe = (comment as dynamic).isLikedByMe as bool? ?? false;

    final TextStyle nameStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    final TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              comment.authorName.isNotEmpty ? comment.authorName.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    style: textStyle,
                    children: <TextSpan>[
                      TextSpan(text: '${comment.authorName} ', style: nameStyle),
                      TextSpan(text: comment.text),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  likeCount > 0
                      ? 'Just now • $likeCount like${likeCount == 1 ? '' : 's'}'
                      : 'Just now',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLikeTap,
            splashRadius: 16,
            icon: Icon(
              isLikedByMe
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 18,
              color: isLikedByMe
                  ? AppColors.accentDanger
                  : AppColors.textMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: isLikedByMe ? 'Unlike comment' : 'Like comment',
          ),
        ],
      ),
    );
  }
}

