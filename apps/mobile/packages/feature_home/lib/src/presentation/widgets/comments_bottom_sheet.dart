import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_confirm_dialog.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/presentation/utils/comment_input_validator.dart';
import 'package:feature_home/src/presentation/utils/comment_mutation_snack.dart';
import 'package:feature_home/src/presentation/utils/comment_thread_navigation.dart';
import 'package:feature_home/src/presentation/widgets/comments/comment_thread_ops.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_bottom_sheet_header.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_input_bar.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_motion.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_sheet_comment_list.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_sheet_drag.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_thread_flatten.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Instagram-style comments bottom sheet: header + scrollable list + sticky input bar.
///
/// This widget is intended to be used as the content of a modal bottom sheet.
class CommentsBottomSheet extends ConsumerStatefulWidget {
  const CommentsBottomSheet({
    super.key,
    required this.comments,
    this.siteId,
    this.siteTitle,
    this.scrollController,
    this.sheetController,
    this.sheetSizeConfig = CommentsSheetSizeConfig.standard,
    this.isLoadingMoreComments = false,
    this.onCommentsCountChanged,
    this.onCommentsChanged,
    this.onLoadMoreDirectReplies,
    this.onCommentSubmitted,
    this.onCommentEdited,
    this.onCommentDeleted,
    this.onCommentLikeToggled,
    this.highlightCommentId,
    this.highlightActorUserId,
    this.ugcModerationRepository,
  });

  final List<Comment> comments;
  final String? highlightCommentId;
  final String? highlightActorUserId;
  final UgcModerationRepository? ugcModerationRepository;
  final String? siteId;
  final String? siteTitle;
  final ScrollController? scrollController;
  final DraggableScrollableController? sheetController;
  final CommentsSheetSizeConfig sheetSizeConfig;
  final bool isLoadingMoreComments;
  final ValueChanged<int>? onCommentsCountChanged;
  final ValueChanged<List<Comment>>? onCommentsChanged;
  final Future<Comment?> Function(String text, String? parentId)?
  onCommentSubmitted;
  final Future<void> Function(String commentId, String body)? onCommentEdited;
  final Future<void> Function(String commentId)? onCommentDeleted;
  // ignore: avoid_positional_boolean_parameters, widget callback signature
  final Future<void> Function(String commentId, bool shouldLike)?
  onCommentLikeToggled;

  /// Fetches the next page of **direct** replies for [parentCommentId] (`GET .../comments?parentId=`).
  final Future<List<Comment>> Function(
    String parentCommentId,
    int page,
    String sort,
  )?
  onLoadMoreDirectReplies;

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  late final List<Comment> _comments;
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;
  final ScrollController _fallbackScrollController = ScrollController();
  String? _replyToCommentId;
  String? _replyToAuthor;
  String? _editingCommentId;
  String? _editingOriginalText;
  final Set<String> _expandedReplyIds = <String>{};
  final Map<String, int> _nextDirectReplyPageByParentId = <String, int>{};
  String? _loadingMoreDirectRepliesForParentId;
  final Map<String, _CommentActionState> _commentActionStates =
      <String, _CommentActionState>{};
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  String? _activeHighlightCommentId;
  Timer? _highlightTimer;
  bool _highlightScheduled = false;
  bool _isCommittingNewComment = false;

  /// API sort for threaded loads (UI sort toggle removed; server default is top-ranked).
  static const String _commentsSort = 'top';

  ScrollController get _listController =>
      widget.scrollController ?? _fallbackScrollController;

  bool get _ownsScrollController => widget.scrollController == null;
  bool get _canPost {
    final String normalized = CommentInputValidator.normalizeBody(
      _commentController.text,
    );
    return normalized.isNotEmpty &&
        CommentInputValidator.withinMaxLength(normalized);
  }

  int get _totalCommentCount => countCommentNodes(_comments);

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scheduleCommentHighlight(),
    );
  }

  GlobalKey _rowKeyFor(String commentId) =>
      _rowKeys.putIfAbsent(commentId, GlobalKey.new);

  void _scheduleCommentHighlight() {
    if (_highlightScheduled) return;
    final String? targetId = resolveHighlightCommentId(
      comments: _comments,
      commentId: widget.highlightCommentId,
      actorUserId: widget.highlightActorUserId,
    );
    if (targetId == null || targetId.isEmpty) return;
    _highlightScheduled = true;
    final List<String> ancestors = findCommentAncestorIds(_comments, targetId);
    void runScrollAndHighlight() {
      scheduleNotificationRowHighlight(
        targetId: targetId,
        rowKey: _rowKeyFor(targetId),
        onHighlight: () {
          if (!mounted) return;
          setState(() => _activeHighlightCommentId = targetId);
          _highlightTimer?.cancel();
          _highlightTimer = Timer(
            NotificationRowHighlight.highlightDuration,
            () {
              if (mounted) {
                setState(() => _activeHighlightCommentId = null);
              }
            },
          );
        },
      );
    }

    if (ancestors.isNotEmpty) {
      setState(() => _expandedReplyIds.addAll(ancestors));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) runScrollAndHighlight();
      });
    } else {
      runScrollAndHighlight();
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _commentController.dispose();
    _commentFocusNode.dispose();
    if (_ownsScrollController) {
      _fallbackScrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CommentsBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.comments, oldWidget.comments)) {
      return;
    }
    if (sameRootCommentOrder(widget.comments, _comments)) {
      return;
    }
    if (widget.comments.length > _comments.length &&
        prefixRootIdsMatch(widget.comments, _comments, _comments.length)) {
      setState(() {
        _comments = List<Comment>.from(widget.comments);
      });
      return;
    }
    setState(() {
      _comments = List<Comment>.from(widget.comments);
    });
  }

  Future<void> _submitComment([String? raw]) async {
    final String text = CommentInputValidator.normalizeBody(
      raw ?? _commentController.text,
    );
    if (text.isEmpty) {
      return;
    }
    if (!CommentInputValidator.withinMaxLength(text)) {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.commentsBodyTooLong,
          type: AppSnackType.warning,
        );
      }
      return;
    }
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
      final List<Comment> before = cloneCommentForest(_comments);
      setState(() {
        _commentActionStates[editingCommentId] = _CommentActionState.editing;
        updateCommentNode(
          _comments,
          editingCommentId,
          (node) => node.copyWith(text: text),
        );
        _editingCommentId = null;
        _editingOriginalText = null;
        _commentController.clear();
      });
      widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
      try {
        await widget.onCommentEdited?.call(editingCommentId, text);
      } on AppError catch (e) {
        if (!mounted) return;
        setState(() {
          _comments
            ..clear()
            ..addAll(before);
        });
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
        showCommentMutationSnack(
          context,
          e,
          fallbackMessage: context.l10n.commentsEditFailedSnack,
        );
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

    final DateTime optimisticAt = DateTime.now();
    final String optimisticAuthor = () {
      final String? n = ref.read(authStateProvider).displayName?.trim();
      if (n != null && n.isNotEmpty) {
        return n;
      }
      return context.l10n.commentsOptimisticAuthorYou;
    }();
    setState(() {
      final newComment = Comment(
        id: localId,
        authorName: optimisticAuthor,
        text: text,
        createdAt: optimisticAt,
        parentId: parentId,
        likeCount: 0,
        isLikedByMe: false,
        isOwnedByMe: true,
      );
      if (parentId == null) {
        _comments.add(newComment);
      } else {
        insertReplyInto(_comments, parentId, newComment);
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
      setState(() => _isCommittingNewComment = true);
      try {
        final Comment? created = await widget.onCommentSubmitted!(
          text,
          parentId,
        );
        if (!mounted || created == null) return;
        setState(() {
          _rowKeys.remove(localId);
          updateCommentNode(_comments, localId, (_) => created);
        });
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
      } on AppError catch (e) {
        if (!mounted) return;
        setState(() {
          removeCommentNode(_comments, localId);
        });
        widget.onCommentsCountChanged?.call(_totalCommentCount);
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
        showCommentMutationSnack(
          context,
          e,
          fallbackMessage: context.l10n.commentsReplyFailedSnack,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          removeCommentNode(_comments, localId);
        });
        widget.onCommentsCountChanged?.call(_totalCommentCount);
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
        AppSnack.show(
          context,
          message: context.l10n.commentsReplyFailedSnack,
          type: AppSnackType.warning,
        );
      } finally {
        if (mounted) {
          setState(() => _isCommittingNewComment = false);
        }
      }
    }
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_commentFocusNode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        CommentsMotion.scrollListToEnd(_listController, context: context),
      );
    });
  }

  Future<void> _openCommentReport(Comment comment) async {
    if (_isCommentBusy(comment.id)) return;
    await showUgcReportSheet(
      context,
      subjectType: 'site_comment',
      subjectId: comment.id,
      repository: widget.ugcModerationRepository,
    );
  }

  Future<void> _blockCommentAuthor(Comment comment) async {
    final String? authorId = comment.authorId?.trim();
    if (authorId == null || authorId.isEmpty) {
      return;
    }
    final bool blocked = await confirmAndBlockUser(
      context,
      blockedUserId: authorId,
      displayName: comment.authorName,
      repository: widget.ugcModerationRepository,
    );
    if (!blocked || !mounted) {
      return;
    }
    setState(() {
      removeCommentsByAuthorId(_comments, authorId);
    });
    widget.onCommentsCountChanged?.call(_totalCommentCount);
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
  }

  Future<void> _openPeerCommentActions(Comment comment) async {
    final l10n = context.l10n;
    final String? action = await showAppActionSheet<String>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: Text(l10n.commentsSheetTitle),
          message: Text(l10n.commentsSheetSubtitle),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop('report'),
              child: Text(l10n.safetyReportTitle),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(sheetContext).pop('block'),
              child: Text(l10n.safetyBlockUserTitle),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text(l10n.commonCancel),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'report') {
      await _openCommentReport(comment);
      return;
    }
    if (action == 'block') {
      await _blockCommentAuthor(comment);
    }
  }

  Future<void> _openCommentActions(Comment comment) async {
    if (_isCommentBusy(comment.id)) return;
    if (!comment.isOwnedByMe) {
      await _openPeerCommentActions(comment);
      return;
    }
    final l10n = context.l10n;
    final String? action = await showAppActionSheet<String>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: Text(l10n.commentsSheetTitle),
          message: Text(l10n.commentsSheetSubtitle),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop('edit'),
              child: Text(l10n.commentsEditTitle),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(sheetContext).pop('delete'),
              child: Text(l10n.commentsDeleteTitle),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text(l10n.commonCancel),
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
      final bool confirmed = await _confirmDeleteComment();
      if (!confirmed || !mounted) return;
      await _deleteComment(comment);
    }
  }

  Future<bool> _confirmDeleteComment() async {
    final l10n = context.l10n;
    final bool? confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.commentsDeleteTitle,
      body: l10n.commentsDeleteConfirmBody,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      isDestructive: true,
    );
    return confirmed == true;
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
  }

  Future<void> _deleteComment(Comment comment) async {
    if (_isCommentBusy(comment.id)) return;
    if (!mounted) return;
    final List<Comment> before = cloneCommentForest(_comments);
    setState(() {
      _commentActionStates[comment.id] = _CommentActionState.deleting;
      removeCommentNode(_comments, comment.id);
      _expandedReplyIds.remove(comment.id);
    });
    widget.onCommentsCountChanged?.call(_totalCommentCount);
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
    try {
      await widget.onCommentDeleted?.call(comment.id);
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.commentsDeletedSnack,
        type: AppSnackType.info,
      );
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(before);
      });
      widget.onCommentsCountChanged?.call(_totalCommentCount);
      widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
      showCommentMutationSnack(
        context,
        e,
        fallbackMessage: context.l10n.commentsDeleteFailedSnack,
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

  void _toggleCommentLike(String commentId) {
    if (_isCommentBusy(commentId)) return;
    final Comment? current = findCommentById(_comments, commentId);
    if (current == null) return;
    final bool nextLiked = !(current.isLikedByMe ?? false);
    final int nextLikeCount = nextLiked
        ? (current.likeCount ?? 0) + 1
        : ((current.likeCount ?? 0) - 1).clamp(0, 9999);
    final int previousLikeCount = current.likeCount ?? 0;
    final bool previousLiked = current.isLikedByMe ?? false;

    setState(() {
      _commentActionStates[commentId] = _CommentActionState.liking;
      updateCommentNode(_comments, commentId, (Comment node) {
        return node.copyWith(isLikedByMe: nextLiked, likeCount: nextLikeCount);
      });
    });
    widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
    widget.onCommentLikeToggled
        ?.call(commentId, nextLiked)
        .then((_) {
          if (!mounted) return;
          setState(() => _commentActionStates.remove(commentId));
        })
        .catchError((Object e, StackTrace _) {
          if (!mounted) return;
          setState(() {
            _commentActionStates[commentId] = _CommentActionState.rollback;
            updateCommentNode(_comments, commentId, (Comment node) {
              return node.copyWith(
                isLikedByMe: previousLiked,
                likeCount: previousLikeCount,
              );
            });
          });
          if (e is AppError) {
            showCommentMutationSnack(
              context,
              e,
              fallbackMessage: context.l10n.commentsLikeFailedSnack,
            );
          } else {
            AppSnack.show(
              context,
              message: context.l10n.commentsLikeFailedSnack,
              type: AppSnackType.warning,
            );
          }
          if (!mounted) return;
          setState(() => _commentActionStates.remove(commentId));
        });
  }

  @override
  Widget build(BuildContext context) {
    final String threadLabel =
        widget.siteTitle != null && widget.siteTitle!.trim().isNotEmpty
        ? '${context.l10n.commentsFeedHeaderTitle}. ${widget.siteTitle!.trim()}.'
        : context.l10n.commentsFeedHeaderTitle;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: threadLabel,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          CommentsBottomSheetHeader(
            siteTitle: widget.siteTitle,
            commentCount: _totalCommentCount,
            sheetController: widget.sheetController,
            sizeConfig: widget.sheetSizeConfig,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Overlay keyboard model: the IME covers the sheet bottom, so
                // shrink the thread area to keep it visible above the keyboard
                // and the lifted composer. Always mounted (value-only change)
                // and clamped to the available height so the simultaneous
                // sheet-expand and keyboard animations can never overflow.
                final double listKeyboardInset = widget.sheetController == null
                    ? 0
                    : math.min(
                        appSheetOverlayKeyboardInset(context),
                        constraints.maxHeight,
                      );
                return Padding(
                  padding: EdgeInsets.only(bottom: listKeyboardInset),
                  child: CommentsSheetCommentList(
                    comments: _comments,
                    expandedReplyIds: _expandedReplyIds,
                    scrollController: _listController,
                    expandedKeyToken:
                        '${_expandedReplyIds.length}-$_activeHighlightCommentId',
                    highlightedCommentId: _activeHighlightCommentId,
                    rowKeyFor: _rowKeyFor,
                    isCommentBusy: _isCommentBusy,
                    isCommentLiking: _isCommentLiking,
                    isCommentEditing: _isCommentEditing,
                    isCommentDeleting: _isCommentDeleting,
                    onLikeTap: _toggleCommentLike,
                    onOpenMenu: _openCommentActions,
                    onReplyTap: (Comment comment) {
                      setState(() {
                        _replyToCommentId = comment.id;
                        _replyToAuthor = comment.authorName;
                        _commentController.text = '@${comment.authorName} ';
                        _commentController.selection =
                            TextSelection.fromPosition(
                              TextPosition(
                                offset: _commentController.text.length,
                              ),
                            );
                      });
                      FocusScope.of(context).requestFocus(_commentFocusNode);
                    },
                    hasExpandableThread: _hasExpandableThread,
                    onToggleReplies: (Comment comment) {
                      setState(() {
                        if (_expandedReplyIds.contains(comment.id)) {
                          _expandedReplyIds.remove(comment.id);
                        } else {
                          _expandedReplyIds.add(comment.id);
                        }
                      });
                    },
                    showLoadMoreReplies: (Comment c) =>
                        _expandedReplyIds.contains(c.id) &&
                        _canPaginateDirectReplies(c),
                    onLoadMoreReplies: (Comment c) =>
                        unawaited(_loadMoreDirectReplies(c)),
                    isLoadingMoreReplies: (Comment c) =>
                        _loadingMoreDirectRepliesForParentId == c.id,
                  ),
                );
              },
            ),
          ),
          if (widget.isLoadingMoreComments) const AppLinearProgress(),
          CommentsInputBar(
            commentController: _commentController,
            commentFocusNode: _commentFocusNode,
            keyboardOverlaysSheet: widget.sheetController != null,
            editingCommentId: _editingCommentId,
            replyToCommentId: _replyToCommentId,
            replyToAuthor: _replyToAuthor,
            canPost: _canPost,
            isCommitting: _isCommittingNewComment,
            onTextChanged: (_) => setState(() {}),
            onCommit: _submitComment,
            onCancelEdit: () => setState(() {
              _editingCommentId = null;
              _editingOriginalText = null;
              _commentController.clear();
            }),
            onCancelReply: () => setState(() {
              _replyToCommentId = null;
              _replyToAuthor = null;
              _editingCommentId = null;
              _editingOriginalText = null;
              _commentController.clear();
            }),
          ),
        ],
      ),
    );
  }

  bool _canPaginateDirectReplies(Comment c) {
    return widget.siteId != null &&
        widget.siteId!.isNotEmpty &&
        widget.onLoadMoreDirectReplies != null &&
        c.repliesCount > c.replies.length;
  }

  bool _hasExpandableThread(Comment c) {
    return c.replies.isNotEmpty || _canPaginateDirectReplies(c);
  }

  Future<void> _loadMoreDirectReplies(Comment parent) async {
    if (widget.siteId == null ||
        widget.siteId!.isEmpty ||
        widget.onLoadMoreDirectReplies == null) {
      return;
    }
    setState(() => _loadingMoreDirectRepliesForParentId = parent.id);
    try {
      final int page = _nextDirectReplyPageByParentId[parent.id] ?? 2;
      final List<Comment> batch = await widget.onLoadMoreDirectReplies!(
        parent.id,
        page,
        _commentsSort,
      );
      if (!mounted) {
        return;
      }
      if (batch.isEmpty) {
        setState(() {});
        return;
      }
      final bool ok = mergeDirectRepliesInto(_comments, parent.id, batch);
      if (ok) {
        _nextDirectReplyPageByParentId[parent.id] = page + 1;
        widget.onCommentsCountChanged?.call(_totalCommentCount);
        widget.onCommentsChanged?.call(List<Comment>.unmodifiable(_comments));
      }
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.feedCommentsLoadMoreFailedSnack,
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() => _loadingMoreDirectRepliesForParentId = null);
      }
    }
  }
}

enum _CommentActionState { liking, editing, deleting, rollback }
