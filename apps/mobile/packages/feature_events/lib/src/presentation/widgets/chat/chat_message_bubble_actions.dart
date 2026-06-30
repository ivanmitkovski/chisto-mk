part of 'package:feature_events/src/presentation/widgets/chat/chat_message_bubble.dart';

/// Context menu, report, and block actions for [ChatMessageBubble].
mixin _ChatMessageBubbleActionsMixin on State<ChatMessageBubble> {
  bool _canReportMessage(EventChatMessage msg) =>
      !msg.isOwnMessage && !msg.isDeleted && !msg.pending;

  bool _canBlockAuthor(EventChatMessage msg) =>
      _canReportMessage(msg) && msg.authorId.isNotEmpty;

  bool _hasAnyMessageAction(EventChatMessage msg) {
    final bool canCopy =
        widget.onCopy != null && msg.body != null && msg.body!.isNotEmpty;
    return canCopy ||
        _canReportMessage(msg) ||
        _canBlockAuthor(msg) ||
        widget.onReply != null ||
        widget.onEdit != null ||
        widget.onPin != null ||
        widget.onUnpin != null ||
        widget.onDelete != null;
  }

  Future<void> _reportMessage(
    BuildContext context,
    EventChatMessage msg,
  ) async {
    await showUgcReportSheet(
      context,
      subjectType: 'event_chat_message',
      subjectId: msg.id,
    );
  }

  Future<void> _blockAuthor(BuildContext context, EventChatMessage msg) async {
    final bool blocked = await confirmAndBlockUser(
      context,
      blockedUserId: msg.authorId,
      displayName: msg.authorName,
    );
    if (blocked) {
      widget.onAuthorBlocked?.call(msg.authorId);
    }
  }

  Future<void> _showActions(BuildContext context) async {
    final EventChatAudioPlaybackController? playback =
        EventChatAudioPlaybackScope.maybeOf(context);
    if (playback != null && playback.activeClipKey == widget.message.id) {
      await playback.stopActiveClip();
    }
    if (!context.mounted) {
      return;
    }

    final EventChatMessage msg = widget.message;
    final bool canCopy =
        widget.onCopy != null && msg.body != null && msg.body!.isNotEmpty;
    final bool canReport = _canReportMessage(msg);
    final bool canBlock = _canBlockAuthor(msg);

    await showAppActionSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoActionSheet(
          actions: <Widget>[
            if (canReport)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(_reportMessage(context, msg));
                },
                child: Text(context.l10n.safetyReportTitle),
              ),
            if (canBlock)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(_blockAuthor(context, msg));
                },
                child: Text(context.l10n.safetyBlockUserTitle),
              ),
            if (canCopy)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onCopy?.call();
                },
                child: Text(context.l10n.eventChatCopy),
              ),
            if (widget.onReply != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onReply?.call();
                },
                child: Text(context.l10n.eventChatReply),
              ),
            if (widget.onEdit != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onEdit?.call();
                },
                child: Text(context.l10n.eventChatEditMessage),
              ),
            if (widget.onPin != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onPin?.call();
                },
                child: Text(context.l10n.eventChatPinMessage),
              ),
            if (widget.onUnpin != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onUnpin?.call();
                },
                child: Text(context.l10n.eventChatUnpinMessage),
              ),
            if (widget.onDelete != null)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onDelete?.call();
                },
                child: Text(context.l10n.eventChatDelete),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
        );
      },
    );
  }
}
