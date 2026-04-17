import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

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
    this.onCommentSubmitted,
    this.onCommentEdited,
    this.onCommentDeleted,
    this.onCommentLikeToggled,
    this.onSortChanged,
    this.initialSort = 'top',
  });

  final List<Comment> comments;
  final String? siteTitle;
  final ScrollController? scrollController;
  final ValueChanged<int>? onCommentsCountChanged;
  final ValueChanged<List<Comment>>? onCommentsChanged;
  final Future<Comment?> Function(String text, String? parentId)? onCommentSubmitted;
  final Future<void> Function(String commentId, String body)? onCommentEdited;
  final Future<void> Function(String commentId)? onCommentDeleted;
  final Future<void> Function(String commentId, bool shouldLike)? onCommentLikeToggled;
  final Future<List<Comment>> Function(String sort)? onSortChanged;
  final String initialSort;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late final List<Comment> _comments;
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;
  final ScrollController _fallbackScrollController = ScrollController();
  String? _replyToCommentId;
  String? _replyToAuthor;
  String? _editingCommentId;
  String? _editingOriginalText;
  final Set<String> _expandedReplyIds = <String>{};
  final Map<String, _CommentActionState> _commentActionStates =
      <String, _CommentActionState>{};

  ScrollController get _listController =>
      widget.scrollController ?? _fallbackScrollController;

  bool get _ownsScrollController => widget.scrollController == null;
  bool get _canPost => _commentController.text.trim().isNotEmpty;

  int get _totalCommentCount => _countNodes(_comments);

  int _countNodes(List<Comment> nodes) {
    int total = 0;
    for (final comment in nodes) {
      total += 1 + _countNodes(comment.replies);
    }
    return total;
  }

  int _safeLikeCount(Comment comment) =>
      (comment as dynamic).likeCount as int? ?? 0;

  bool _safeIsLikedByMe(Comment comment) =>
      (comment as dynamic).isLikedByMe as bool? ?? false;

  bool _isCommentBusy(String id) => _commentActionStates.containsKey(id);

  bool _isCommentLiking(String id) =>
      _commentActionStates[id] == _CommentActionState.liking;

  bool _isCommentEditing(String id) =>
      _commentActionStates[id] == _CommentActionState.editing;

  bool _isCommentDeleting(String id) =>
      _commentActionStates[id] == _CommentActionState.deleting;

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

  Future<void> _submitComment([String? raw]) async {
    final String text = (raw ?? _commentController.text).trim();
    if (text.isEmpty) return;
    final String? editingCommentId = _editingCommentId;
    if (editingCommentId != null) {
      if (_isCommentBusy(editingCommentId)) return;
      final String originalText = _editingOriginalText ?? '';
      if (text == originalText.trim()) {
        setState(() {
          _editingCommentId = null;
          _editingOriginalText = null;
          _commentController.clear();
        });
        return;
      }
      final List<Comment> before = _cloneComments(_comments);
      AppHaptics.tap(context);
      setState(() {
        _commentActionStates[editingCommentId] = _CommentActionState.editing;
        _updateCommentNode(_comments, editingCommentId, (node) => node.copyWith(text: text));
        _editingCommentId = null;
        _editingOriginalText = null;
        _commentController.clear();
      });
      widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
      try {
        await widget.onCommentEdited?.call(editingCommentId, text);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _comments
            ..clear()
            ..addAll(before);
        });
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
        AppSnack.show(
          context,
          message: context.l10n.commentsEditFailedSnack,
          type: AppSnackType.warning,
        );
      } finally {
        if (mounted) {
          setState(() => _commentActionStates.remove(editingCommentId));
        }
      }
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_commentFocusNode);
      return;
    }
    final String? parentId = _replyToCommentId;
    final String localId = 'local-${DateTime.now().microsecondsSinceEpoch}';

    AppHaptics.light(context);
    setState(() {
      final newComment = Comment(
        id: localId,
        authorName: 'you',
        text: text,
        parentId: parentId,
        likeCount: 0,
        isLikedByMe: false,
        isOwnedByMe: true,
      );
      if (parentId == null) {
        _comments.add(newComment);
      } else {
        _insertReply(_comments, parentId, newComment);
        _expandedReplyIds.add(parentId);
      }
      _replyToCommentId = null;
      _replyToAuthor = null;
      _editingCommentId = null;
      _editingOriginalText = null;
      _commentController.clear();
    });

    widget.onCommentsCountChanged?.call(_totalCommentCount);
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
    if (widget.onCommentSubmitted != null) {
      try {
        final Comment? created = await widget.onCommentSubmitted!(text, parentId);
        if (!mounted || created == null) return;
        setState(() {
          _updateCommentNode(_comments, localId, (_) => created);
        });
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _removeCommentNode(_comments, localId);
        });
        widget.onCommentsCountChanged?.call(_totalCommentCount);
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
        AppSnack.show(
          context,
          message: context.l10n.commentsReplyFailedSnack,
          type: AppSnackType.warning,
        );
      }
    }
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_commentFocusNode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      if (_listController.positions.length != 1) return;
      _listController.animateTo(
        _listController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _insertReply(List<Comment> nodes, String parentId, Comment reply) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.id == parentId) {
        nodes[i] = node.copyWith(replies: <Comment>[reply, ...node.replies]);
        return true;
      }
      final List<Comment> mutableReplies = List<Comment>.from(node.replies);
      if (_insertReply(mutableReplies, parentId, reply)) {
        nodes[i] = node.copyWith(replies: mutableReplies);
        return true;
      }
    }
    return false;
  }

  bool _removeCommentNode(List<Comment> nodes, String id) {
    final int index = nodes.indexWhere((c) => c.id == id);
    if (index >= 0) {
      nodes.removeAt(index);
      return true;
    }
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final List<Comment> mutableReplies = List<Comment>.from(node.replies);
      if (_removeCommentNode(mutableReplies, id)) {
        nodes[i] = node.copyWith(replies: mutableReplies);
        return true;
      }
    }
    return false;
  }

  List<Comment> _cloneComments(List<Comment> nodes) {
    return nodes
        .map(
          (node) => node.copyWith(
            replies: _cloneComments(node.replies),
          ),
        )
        .toList();
  }

  Future<void> _openCommentActions(Comment comment) async {
    if (_isCommentBusy(comment.id)) return;
    final String? action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return ReportSheetScaffold(
          fitToContent: true,
          addBottomInset: false,
          title: context.l10n.commentsSheetTitle,
          subtitle: context.l10n.commentsSheetSubtitle,
          trailing: ReportCircleIconButton(
            icon: Icons.close_rounded,
            semanticLabel: context.l10n.semanticClose,
            onTap: () => Navigator.of(context).pop(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ReportActionTile(
                icon: Icons.edit_outlined,
                title: context.l10n.commentsEditTitle,
                subtitle: context.l10n.commentsEditSubtitle,
                onTap: () => Navigator.of(context).pop('edit'),
                tone: ReportSurfaceTone.neutral,
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportActionTile(
                icon: Icons.delete_outline_rounded,
                title: context.l10n.commentsDeleteTitle,
                subtitle: context.l10n.commentsDeleteSubtitle,
                onTap: () => Navigator.of(context).pop('delete'),
                tone: ReportSurfaceTone.danger,
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      _startInlineEdit(comment);
      return;
    }
    if (action == 'delete') {
      await _deleteComment(comment);
    }
  }

  void _startInlineEdit(Comment comment) {
    if (_isCommentBusy(comment.id)) return;
    setState(() {
      _editingCommentId = comment.id;
      _editingOriginalText = comment.text;
      _replyToCommentId = null;
      _replyToAuthor = null;
      _commentController.text = comment.text;
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    FocusScope.of(context).requestFocus(_commentFocusNode);
    AppHaptics.tap(context);
  }

  Future<void> _deleteComment(Comment comment) async {
    if (_isCommentBusy(comment.id)) return;
    if (!mounted) return;
    AppHaptics.medium(context);
    final List<Comment> before = _cloneComments(_comments);
    setState(() {
      _commentActionStates[comment.id] = _CommentActionState.deleting;
      _removeCommentNode(_comments, comment.id);
      _expandedReplyIds.remove(comment.id);
    });
    widget.onCommentsCountChanged?.call(_totalCommentCount);
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
    try {
      await widget.onCommentDeleted?.call(comment.id);
      if (!mounted) return;
      AppHaptics.light(context);
      AppSnack.show(
        context,
        message: context.l10n.commentsDeletedSnack,
        type: AppSnackType.info,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(before);
      });
      widget.onCommentsCountChanged?.call(_totalCommentCount);
      widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
      AppSnack.show(
        context,
        message: context.l10n.commentsDeleteFailedSnack,
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() {
          _commentActionStates.remove(comment.id);
        });
      }
    }
  }

  List<_FlattenedComment> _flattenComments(List<Comment> comments, {int depth = 0}) {
    final List<_FlattenedComment> out = <_FlattenedComment>[];
    for (final comment in comments) {
      out.add(_FlattenedComment(comment: comment, depth: depth));
      if (_expandedReplyIds.contains(comment.id)) {
        out.addAll(_flattenComments(comment.replies, depth: depth + 1));
      }
    }
    return out;
  }

  void _toggleCommentLike(String commentId) {
    if (_isCommentBusy(commentId)) return;
    final Comment? current = _findCommentById(_comments, commentId);
    if (current == null) return;
    final bool nextLiked = !_safeIsLikedByMe(current);
    final int nextLikeCount = nextLiked
        ? _safeLikeCount(current) + 1
        : (_safeLikeCount(current) - 1).clamp(0, 9999);

    AppHaptics.tap(context);
    setState(() {
      _commentActionStates[commentId] = _CommentActionState.liking;
      _updateCommentNode(_comments, commentId, (Comment node) {
        return node.copyWith(
          isLikedByMe: nextLiked,
          likeCount: nextLikeCount,
        );
      });
    });
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
    widget.onCommentLikeToggled?.call(commentId, nextLiked).then((_) {
      if (!mounted) return;
      setState(() => _commentActionStates.remove(commentId));
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _commentActionStates[commentId] = _CommentActionState.rollback;
        _updateCommentNode(_comments, commentId, (Comment node) {
          final int currentLikes = _safeLikeCount(node);
          return node.copyWith(
            isLikedByMe: !nextLiked,
            likeCount: nextLiked ? (currentLikes - 1).clamp(0, 9999) : currentLikes + 1,
          );
        });
      });
      AppSnack.show(
        context,
        message: context.l10n.commentsLikeFailedSnack,
        type: AppSnackType.warning,
      );
      if (!mounted) return;
      setState(() => _commentActionStates.remove(commentId));
    });
  }

  Comment? _findCommentById(List<Comment> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final nested = _findCommentById(node.replies, id);
      if (nested != null) return nested;
    }
    return null;
  }

  bool _updateCommentNode(
    List<Comment> nodes,
    String id,
    Comment Function(Comment current) transform,
  ) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.id == id) {
        nodes[i] = transform(node);
        return true;
      }
      final replies = List<Comment>.from(node.replies);
      if (_updateCommentNode(replies, id, transform)) {
        nodes[i] = node.copyWith(replies: replies);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
              : Builder(
                  builder: (BuildContext context) {
                    final flattened = _flattenComments(_comments);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: ListView.separated(
                  key: ValueKey<String>(
                    '${_expandedReplyIds.length}-${flattened.length}',
                  ),
                  controller: _listController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  itemCount: flattened.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (BuildContext context, int index) {
                    final _FlattenedComment item = flattened[index];
                    final Comment comment = item.comment;
                    return _CommentTile(
                      comment: comment,
                      depth: item.depth,
                      isBusy: _isCommentBusy(comment.id),
                      isLiking: _isCommentLiking(comment.id),
                      isEditing: _isCommentEditing(comment.id),
                      isDeleting: _isCommentDeleting(comment.id),
                      onLikeTap: () => _toggleCommentLike(comment.id),
                      onOpenMenu: comment.isOwnedByMe
                          ? () => _openCommentActions(comment)
                          : null,
                      onReplyTap: () {
                        setState(() {
                          _replyToCommentId = comment.id;
                          _replyToAuthor = comment.authorName;
                          _commentController.text = '@${comment.authorName} ';
                          _commentController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _commentController.text.length),
                          );
                        });
                        FocusScope.of(context).requestFocus(_commentFocusNode);
                      },
                      hasReplies: comment.replies.isNotEmpty,
                      repliesExpanded: _expandedReplyIds.contains(comment.id),
                      onToggleReplies: comment.replies.isEmpty
                          ? null
                          : () {
                              setState(() {
                                if (_expandedReplyIds.contains(comment.id)) {
                                  _expandedReplyIds.remove(comment.id);
                                } else {
                                  _expandedReplyIds.add(comment.id);
                                }
                              });
                            },
                    );
                  },
                ),
                    );
                  },
                ),
        ),
        _buildAddCommentBar(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    void maybeClose() {
      Navigator.of(context).maybePop();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            onVerticalDragEnd: (DragEndDetails details) {
              // If the user flicks the header downward with enough velocity,
              // dismiss the sheet (Instagram / Apple-style).
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 200) {
                maybeClose();
              }
            },
            child: Center(
              child: Container(
                width: 36,
                height: 5,
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
          const SizedBox(height: AppSpacing.xs),
          if (widget.siteTitle != null && widget.siteTitle!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
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
            ? mediaQuery.viewInsets.bottom + AppSpacing.xs
            : AppSpacing.md + mediaQuery.padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 20,
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 36,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _editingCommentId != null
                        ? Text(
                            'Editing comment',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          )
                        : _replyToCommentId == null
                            ? const SizedBox.shrink()
                            : Text(
                            'Replying to ${_replyToAuthor ?? 'comment'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 36,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _editingCommentId != null
                        ? Semantics(
                            button: true,
                            label: context.l10n.commentsCancelEditSemantic,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _editingCommentId = null;
                                _editingOriginalText = null;
                                _commentController.clear();
                              }),
                              child: const Center(
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          )
                        : _replyToCommentId == null
                            ? const SizedBox.shrink()
                            : Semantics(
                            button: true,
                            label: context.l10n.commentsCancelReplySemantic,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _replyToCommentId = null;
                                _replyToAuthor = null;
                                _editingCommentId = null;
                                _editingOriginalText = null;
                                _commentController.clear();
                              }),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    hintText: _editingCommentId != null
                        ? 'Edit your comment...'
                        : (_replyToCommentId == null ? 'Add a comment...' : 'Write a reply...'),
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: AppColors.inputFill.withValues(alpha: 0.9),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _replyToCommentId != null &&
                                _commentController.text.trim().startsWith(
                                  '@${_replyToAuthor ?? ''}',
                                )
                            ? AppColors.primaryDark
                            : null,
                        fontWeight: _replyToCommentId != null &&
                                _commentController.text.trim().startsWith(
                                  '@${_replyToAuthor ?? ''}',
                                )
                            ? FontWeight.w600
                            : null,
                      ),
                  onSubmitted: (String value) => _submitComment(value),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _canPost ? 1 : 0.45,
                child: Material(
                  color: AppColors.transparent,
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
                        _editingCommentId == null
                            ? Icons.arrow_upward_rounded
                            : Icons.check_rounded,
                        size: 18,
                        color: _canPost ? AppColors.textOnDark : AppColors.textMuted,
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({
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

  @override
  Widget build(BuildContext context) {
    final int likeCount = (comment as dynamic).likeCount as int? ?? 0;
    final bool isLikedByMe = (comment as dynamic).isLikedByMe as bool? ?? false;

    final TextStyle nameStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    final TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    );

    final double indent = (depth * 18).clamp(0, 54).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: indent),
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
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: isBusy ? 0.7 : 1,
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
                  isDeleting
                      ? 'Deleting...'
                      : isEditing
                          ? 'Saving edits...'
                          : likeCount > 0
                              ? 'Just now • $likeCount like${likeCount == 1 ? '' : 's'}'
                              : 'Just now',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  button: true,
                  label: context.l10n.commentsReplyToSemantic(comment.authorName),
                  child: GestureDetector(
                    onTap: onReplyTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Reply',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
                if (hasReplies)
                  Semantics(
                    button: true,
                    label: repliesExpanded
                        ? 'Hide replies for ${comment.authorName}'
                        : 'View replies for ${comment.authorName}',
                    child: GestureDetector(
                      onTap: onToggleReplies,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              repliesExpanded ? 'Hide replies' : 'View replies',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 2),
                            AnimatedRotation(
                              turns: repliesExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
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
                  ],
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
                label: isLikedByMe ? 'Unlike comment' : 'Like comment',
                child: IconButton(
                  onPressed: isBusy && !isLiking ? null : onLikeTap,
                  splashRadius: 16,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: isLiking
                        ? const SizedBox(
                            key: ValueKey<String>('liking'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.8),
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
                  tooltip: isLikedByMe ? 'Unlike comment' : 'Like comment',
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
    );
  }
}

class _FlattenedComment {
  const _FlattenedComment({
    required this.comment,
    required this.depth,
  });

  final Comment comment;
  final int depth;
}

enum _CommentActionState {
  liking,
  editing,
  deleting,
  rollback,
}

