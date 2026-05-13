import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_action_row.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_bubble_image_tile.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_document_open_flow.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_image_gallery_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_linkified_text.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_location_fullscreen_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/event_chat_audio_playback_scope.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_video_player_screen.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_action_sheet.dart';
import 'package:chisto_mobile/shared/utils/cached_tile_provider.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.showAuthorName,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.highlighted = false,
    this.onReply,
    this.onReplySnippetTap,
    this.onDelete,
    this.onRetry,
    this.onCopy,
    this.onEdit,
    this.onPin,
    this.onUnpin,
    this.receiptSeenByLine,
    this.receiptAllPeersRead = false,
    this.uploadFraction,
    this.onCancelUpload,
  });

  final EventChatMessage message;
  final bool showAuthorName;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool highlighted;
  final VoidCallback? onReply;
  final VoidCallback? onReplySnippetTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;
  final String? receiptSeenByLine;
  final bool receiptAllPeersRead;

  /// 0–1 while a pending attachment upload is in progress; null when not uploading.
  final double? uploadFraction;

  /// Requests upload cancellation (repository surfaces this as a cancelled error).
  final VoidCallback? onCancelUpload;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;
  late final AnimationController _pulseController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    final bool own = widget.message.isOwnMessage;
    _entranceController = AnimationController(vsync: this, duration: AppMotion.chatBubbleEntrance);
    _entranceOpacity =
        CurvedAnimation(parent: _entranceController, curve: AppMotion.chatBubbleEntranceCurve);
    _entranceSlide = Tween<Offset>(
      begin: Offset(own ? 0.12 : -0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: AppMotion.chatBubbleEntranceCurve));
    _pulseController = AnimationController(vsync: this, duration: AppMotion.medium);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
      _syncPulse(reduceMotion);
    });
  }

  void _syncPulse(bool reduceMotion) {
    if (!mounted) return;
    if (widget.highlighted && !reduceMotion) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..reset();
    }
  }

  @override
  void didUpdateWidget(ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlighted != widget.highlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncPulse(MediaQuery.disableAnimationsOf(context));
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EventChatMessage m = widget.message;
    final bool own = m.isOwnMessage;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final String timeStr =
        DateFormat.jm(Localizations.localeOf(context).toString()).format(m.createdAt.toLocal());
    final String bodyText = m.isDeleted ? context.l10n.eventChatMessageRemoved : (m.body ?? '');
    final String semBody = m.isDeleted ? bodyText : (m.body ?? '');
    String semanticsLabel = context.l10n.eventChatSemanticsBubble(m.authorName, timeStr, semBody);
    if (widget.receiptSeenByLine != null && widget.receiptSeenByLine!.isNotEmpty) {
      semanticsLabel = '$semanticsLabel. ${widget.receiptSeenByLine}';
    }
    if (m.pending) {
      semanticsLabel = '$semanticsLabel. ${context.l10n.eventChatSending}';
    }

    final Color bg = m.isDeleted
        ? ChatTheme.bubbleDeletedFill
        : m.failed
            ? ChatTheme.bubbleFailedFill
            : own
                ? ChatTheme.bubbleOwnFill
                : ChatTheme.bubblePeerFill;
    final Color fg = m.isDeleted
        ? AppColors.textMuted
        : m.failed
            ? AppColors.accentDanger
            : AppColors.textPrimary;

    final Color borderColor = m.failed
        ? ChatTheme.failedBorder
        : widget.highlighted
            ? ChatTheme.highlightBorder(true)
            : m.isDeleted
                ? AppColors.transparent
                : ChatTheme.bubbleNormalBorder(own);
    final double borderWidth =
        m.isDeleted ? 0 : (m.failed ? 1 : ChatTheme.highlightBorderWidth(widget.highlighted));

    final TextDirection direction = Directionality.of(context);
    final BorderRadius br = ChatTheme.bubbleRadius(
      own: own,
      isFirstInGroup: widget.isFirstInGroup,
      isLastInGroup: widget.isLastInGroup,
    ).resolve(direction);

    final Widget bubbleContent = _buildContent(context, m, own, fg, timeStr);
    final Widget bubbleCore = AnimatedScale(
      scale: _pressed && !reduceMotion ? 0.97 : 1.0,
      duration: AppMotion.xFast,
      curve: AppMotion.emphasized,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (BuildContext context, Widget? child) {
          final List<BoxShadow> shadows = m.isDeleted
              ? const <BoxShadow>[]
              : <BoxShadow>[
                  if (own) ...ChatTheme.bubbleOwnShadow else ...ChatTheme.bubblePeerShadow,
                  if (widget.highlighted) ...ChatTheme.highlightPulse(_pulseController.value),
                ];
          return Container(
            decoration: BoxDecoration(borderRadius: br, boxShadow: shadows),
            child: ClipRRect(
              borderRadius: br,
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: br,
                  border: borderWidth > 0
                      ? Border.all(color: borderColor, width: borderWidth)
                      : null,
                ),
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: m.failed
                        ? () {
                            AppHaptics.light();
                            widget.onRetry?.call();
                          }
                        : null,
                    onLongPress: (m.isDeleted || m.pending)
                        ? null
                        : () {
                            AppHaptics.tap(context);
                            unawaited(_showActions(context));
                          },
                    onHighlightChanged: reduceMotion
                        ? null
                        : (bool v) => setState(() => _pressed = v),
                    splashColor: AppColors.primary.withValues(alpha: 0.06),
                    highlightColor: AppColors.primary.withValues(alpha: 0.03),
                    borderRadius: br,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.sm - 2,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: bubbleContent,
      ),
    );

    final bool showAvatar = !own && widget.isLastInGroup;

    Widget row;
    if (own) {
      row = Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FractionallySizedBox(
          widthFactor: 0.78,
          alignment: AlignmentDirectional.centerEnd,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: bubbleCore,
          ),
        ),
      );
    } else {
      row = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SizedBox(
            width: ChatTheme.avatarSize,
            height: ChatTheme.avatarSize,
            child: showAvatar ? _buildAvatar(m) : null,
          ),
          SizedBox(width: ChatTheme.avatarGap),
          Flexible(child: bubbleCore),
        ],
      );
    }

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: FadeTransition(
        opacity: _entranceOpacity,
        child: SlideTransition(position: _entranceSlide, child: row),
      ),
    );
  }

  Widget _buildAvatar(EventChatMessage m) {
    return UserAvatarCircle(
      displayName: m.authorName,
      imageUrl: m.authorAvatarUrl,
      size: ChatTheme.avatarSize,
      seed: m.authorId,
      fallbackStyle: UserAvatarFallbackStyle.softTint,
    );
  }

  Widget _buildContent(
    BuildContext context,
    EventChatMessage m,
    bool own,
    Color fg,
    String timeStr,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle metaStyle =
        AppTypography.eventsChatTimestamp(textTheme, color: ChatTheme.metaText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.showAuthorName && !own) ...<Widget>[
          Text(
            m.authorName,
            style: AppTypography.eventsChatAuthorName(textTheme).copyWith(
                  color: ChatTheme.avatarColor(m.authorId),
                ),
          ),
          const SizedBox(height: 2),
        ],
        if (m.replyToSnippet != null && m.replyToSnippet!.isNotEmpty)
          GestureDetector(
            onTap: widget.onReplySnippetTap,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ChatTheme.replyQuoteFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: BorderDirectional(
                    start: BorderSide(width: 3, color: ChatTheme.replyQuoteBar),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm - 2),
                  child: Text(
                    m.replyToSnippet!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.eventsGridPropertyValue(textTheme),
                  ),
                ),
              ),
            ),
          ),
        if (m.attachments.isNotEmpty && !m.isDeleted)
          Padding(
            padding: EdgeInsets.only(bottom: (m.body != null && m.body!.isNotEmpty) ? AppSpacing.xs : 0),
            child: _buildMediaContent(context, m, own),
          ),
        if (m.messageType == EventChatMessageType.location &&
            !m.isDeleted &&
            m.locationLat != null && m.locationLng != null)
          Padding(
            padding: EdgeInsets.only(bottom: (m.body != null && m.body!.isNotEmpty) ? AppSpacing.xs : 0),
            child: _LocationPreview(
              lat: m.locationLat!,
              lng: m.locationLng!,
              label: m.locationLabel,
            ),
          ),
        if (m.failed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (m.body != null && m.body!.isNotEmpty)
                ChatLinkifiedText(
                  text: m.body!,
                  style: AppTypography.eventsChatMessageBody(textTheme),
                ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.error_outline, size: 14, color: AppColors.accentDanger),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    context.l10n.eventChatSendFailed,
                    style: AppTypography.eventsDestructiveCaption(textTheme),
                  ),
                ],
              ),
            ],
          )
        else if (m.isDeleted)
          Text(
            context.l10n.eventChatMessageRemoved,
            style: AppTypography.eventsChatMessageBody(
                  textTheme,
                  color: AppColors.textMuted,
                )
                .copyWith(fontStyle: FontStyle.italic),
          )
        else if (m.body != null && m.body!.isNotEmpty)
          ChatLinkifiedText(
            text: m.body!,
            style: AppTypography.eventsChatMessageBody(textTheme, color: fg),
          ),
        if (m.pending)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.schedule, size: 12, color: ChatTheme.metaText),
                    const SizedBox(width: 3),
                    Text(context.l10n.eventChatSending, style: metaStyle),
                  ],
                ),
                if (widget.uploadFraction != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: widget.uploadFraction!.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: ChatTheme.replyQuoteFill,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  if (widget.onCancelUpload != null)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () {
                          AppHaptics.light(context);
                          widget.onCancelUpload!();
                        },
                        child: Text(context.l10n.commonCancel),
                      ),
                    ),
                ],
              ],
            ),
          ),
        if (!m.pending && !m.failed)
          _buildMetaRow(context, m, own, timeStr, metaStyle),
      ],
    );
  }

  VoidCallback? _mediaMessageActionsCallback(BuildContext context, EventChatMessage m) {
    final bool canOpen = !m.isDeleted && !m.pending && _hasAnyMessageAction(m);
    if (!canOpen) {
      return null;
    }
    return () {
      AppHaptics.tap(context);
      unawaited(_showActions(context));
    };
  }

  Widget _buildMediaContent(BuildContext context, EventChatMessage m, bool own) {
    final String mime = m.attachments.first.mimeType.toLowerCase();
    if (mime.startsWith('video/')) {
      return _VideoPreview(
        attachment: m.attachments.first,
        onOpenMessageActions: _mediaMessageActionsCallback(context, m),
      );
    }
    if (mime.startsWith('audio/')) {
      final bool canOpenActions = !m.isDeleted &&
          !m.pending &&
          _hasAnyMessageAction(m);
      return _ChatAudioInline(
        clipKey: m.id,
        attachment: m.attachments.first,
        own: own,
        onOpenMessageActions: canOpenActions
            ? () {
                AppHaptics.tap(context);
                unawaited(_showActions(context));
              }
            : null,
      );
    }
    if (mime.startsWith('application/') || mime.startsWith('text/')) {
      return _DocumentPreview(
        attachment: m.attachments.first,
        onOpenMessageActions: _mediaMessageActionsCallback(context, m),
      );
    }
    return _ImageGrid(
      attachments: m.attachments,
      onOpenMessageActions: _mediaMessageActionsCallback(context, m),
    );
  }

  Widget _buildMetaRow(
    BuildContext context,
    EventChatMessage m,
    bool own,
    String timeStr,
    TextStyle? metaStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: own ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (m.editedAt != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xxs),
              child: Text(context.l10n.eventChatEdited, style: metaStyle),
            ),
          if (m.isPinned)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 3),
              child: Icon(CupertinoIcons.pin, size: 10, color: ChatTheme.metaText),
            ),
          Text(
            timeStr,
            style: metaStyle,
            textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.34),
          ),
          if (own && !m.isDeleted && m.messageType == EventChatMessageType.text)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 3),
              child: Icon(
                widget.receiptSeenByLine != null ? Icons.done_all : Icons.done,
                size: 14,
                color: widget.receiptSeenByLine != null && widget.receiptAllPeersRead
                    ? AppColors.primary
                    : ChatTheme.metaText,
              ),
            ),
        ],
      ),
    );
  }

  bool _hasAnyMessageAction(EventChatMessage msg) {
    final bool canCopy =
        widget.onCopy != null && msg.body != null && msg.body!.isNotEmpty;
    return canCopy ||
        widget.onReply != null ||
        widget.onEdit != null ||
        widget.onPin != null ||
        widget.onUnpin != null ||
        widget.onDelete != null;
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
    final bool ios = Theme.of(context).platform == TargetPlatform.iOS;

    if (ios) {
      await showAppActionSheet<void>(
        context: context,
        builder: (BuildContext ctx) {
          return CupertinoActionSheet(
            actions: <Widget>[
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
                    AppHaptics.medium(context);
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
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              if (canCopy)
                ChatMessageActionRow(
                  icon: CupertinoIcons.doc_on_doc,
                  label: context.l10n.eventChatCopy,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onCopy?.call();
                  },
                ),
              if (widget.onReply != null)
                ChatMessageActionRow(
                  icon: CupertinoIcons.reply,
                  label: context.l10n.eventChatReply,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onReply?.call();
                  },
                ),
              if (widget.onEdit != null)
                ChatMessageActionRow(
                  icon: CupertinoIcons.pencil,
                  label: context.l10n.eventChatEditMessage,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onEdit?.call();
                  },
                ),
              if (widget.onPin != null)
                ChatMessageActionRow(
                  icon: CupertinoIcons.pin,
                  label: context.l10n.eventChatPinMessage,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onPin?.call();
                  },
                ),
              if (widget.onUnpin != null)
                ChatMessageActionRow(
                  icon: CupertinoIcons.pin_slash,
                  label: context.l10n.eventChatUnpinMessage,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onUnpin?.call();
                  },
                ),
              if (widget.onDelete != null)
                ChatMessageActionRow(
                  icon: CupertinoIcons.trash,
                  label: context.l10n.eventChatDelete,
                  onTap: () {
                    AppHaptics.medium(context);
                    Navigator.pop(ctx);
                    widget.onDelete?.call();
                  },
                  destructive: true,
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.attachments,
    this.onOpenMessageActions,
  });
  final List<EventChatAttachment> attachments;
  final VoidCallback? onOpenMessageActions;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    if (attachments.length == 1) {
      return _buildSingle(context, attachments.first);
    }
    return _buildGrid(context);
  }

  Widget _buildSingle(BuildContext context, EventChatAttachment a) {
    final double aspectRatio = (a.width != null && a.height != null && a.height! > 0)
        ? a.width!.toDouble() / a.height!.toDouble()
        : 4 / 3;
    return Semantics(
      button: true,
      label: context.l10n.eventChatImageViewerTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.light();
            unawaited(
              openChatImageGallery(
                context,
                attachments: attachments,
                initialIndex: attachments.indexOf(a),
              ),
            );
          },
          onLongPress: onOpenMessageActions,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AspectRatio(
              aspectRatio: aspectRatio.clamp(0.5, 2.0),
              child: eventChatImageTile(a, cacheWidth: 600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final int count = attachments.length.clamp(0, 4);
    final bool hasMore = attachments.length > 4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        height: 160,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < count; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AppHaptics.light();
                      unawaited(
                        openChatImageGallery(
                          context,
                          attachments: attachments,
                          initialIndex: i,
                        ),
                      );
                    },
                    onLongPress: onOpenMessageActions,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        eventChatImageTile(attachments[i], cacheWidth: 300),
                        if (hasMore && i == count - 1)
                          Container(
                            color: Colors.black45,
                            alignment: Alignment.center,
                            child: Text(
                              '+${attachments.length - count}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.attachment,
    this.onOpenMessageActions,
  });
  final EventChatAttachment attachment;
  final VoidCallback? onOpenMessageActions;

  String _formatDuration(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String? thumb = attachment.thumbnailUrl;
    final bool remoteVideo = isEventChatRemoteAttachmentUrl(attachment.url);
    return Semantics(
      button: true,
      label: context.l10n.eventChatVideoViewerTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.light();
            unawaited(openChatVideoPlayer(context, videoUrl: attachment.url));
          },
          onLongPress: onOpenMessageActions,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (thumb != null && remoteVideo)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      cacheKey: '${eventChatAttachmentCacheKey(attachment)}_thumb',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                    )
                  else if (!remoteVideo)
                    Container(
                      color: const Color(0xFF1C1C1E),
                      width: double.infinity,
                      height: 180,
                      alignment: Alignment.center,
                      child: Icon(CupertinoIcons.videocam_fill, size: 52, color: AppColors.textMuted),
                    )
                  else
                    Container(
                      color: AppColors.inputFill,
                      width: double.infinity,
                      height: 180,
                      child: Icon(CupertinoIcons.videocam_fill, size: 48, color: AppColors.textMuted),
                    ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.play_fill, size: 28, color: Colors.white),
                  ),
                  if (attachment.duration != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(attachment.duration!),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatAudioInline extends StatelessWidget {
  const _ChatAudioInline({
    required this.clipKey,
    required this.attachment,
    required this.own,
    this.onOpenMessageActions,
  });

  final String clipKey;
  final EventChatAttachment attachment;
  final bool own;
  final VoidCallback? onOpenMessageActions;

  @override
  Widget build(BuildContext context) {
    final EventChatAudioPlaybackController? playback =
        EventChatAudioPlaybackScope.maybeOf(context);
    final bool playing = playback != null && playback.isActiveAndPlaying(clipKey);
    const double outer = 44;
    const double inner = 32;
    final String totalLabel = _ChatAudioTimeline.fmtDurationMmSs(attachment.duration);
    final EventChatAudioPlaybackController? pb = playback;
    final Duration posForSemantics =
        (pb != null && pb.isActive(clipKey)) ? pb.player.position : Duration.zero;

    return Semantics(
      button: playback != null,
      label:
          '${context.l10n.eventChatAudioExpandedTitle}. ${_ChatAudioTimeline.fmtDurationFromDuration(posForSemantics)} / $totalLabel',
      child: GestureDetector(
        onLongPress: onOpenMessageActions,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: playback == null
                    ? null
                    : () {
                        AppHaptics.light();
                        unawaited(playback.toggle(clipKey, attachment.url));
                      },
                child: SizedBox(
                  width: outer,
                  height: outer,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: outer,
                        height: outer,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: inner,
                        height: inner,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChatAudioTimeline(
                  clipKey: clipKey,
                  attachment: attachment,
                  own: own,
                  playback: playback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress track + elapsed / total while this clip is active; idle shows empty track and length.
class _ChatAudioTimeline extends StatelessWidget {
  const _ChatAudioTimeline({
    required this.clipKey,
    required this.attachment,
    required this.own,
    required this.playback,
  });

  final String clipKey;
  final EventChatAttachment attachment;
  final bool own;
  final EventChatAudioPlaybackController? playback;

  static String fmtDurationMmSs(int? seconds) {
    if (seconds == null || seconds < 0) {
      return '0:00';
    }
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String fmtDurationFromDuration(Duration d) {
    final int sec = d.inSeconds.clamp(0, 35999);
    return fmtDurationMmSs(sec);
  }

  static Duration _totalFromAttachment(EventChatAttachment a) {
    final int? s = a.duration;
    if (s != null && s > 0) {
      return Duration(seconds: s);
    }
    return Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final Color timeColor =
        own ? AppColors.primary.withValues(alpha: 0.92) : AppColors.textSecondary;
    final Color trackBg =
        own ? AppColors.primary.withValues(alpha: 0.22) : AppColors.inputFill;
    final Color trackFg = AppColors.primary;
    final TextTheme audioTextTheme = Theme.of(context).textTheme;
    final TextStyle timeStyle = AppTypography.eventsChatTimestamp(audioTextTheme).copyWith(
          fontWeight: FontWeight.w600,
          color: timeColor,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        );

    final EventChatAudioPlaybackController? p = playback;
    final bool active = p != null && p.isActive(clipKey);
    if (!active) {
      final Duration total = _totalFromAttachment(attachment);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _AudioTimelineBar(
            progress: 0,
            trackBg: trackBg,
            trackFg: trackFg,
            seekable: false,
            onSeekFraction: null,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(fmtDurationFromDuration(Duration.zero), style: timeStyle),
              Text(fmtDurationFromDuration(total), style: timeStyle),
            ],
          ),
        ],
      );
    }

    final EventChatAudioPlaybackController ctrl = p;

    return StreamBuilder<Duration>(
      stream: ctrl.player.positionStream,
      initialData: ctrl.player.position,
      builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
        final Duration pos = snapshot.data ?? Duration.zero;
        Duration total = ctrl.player.duration ?? _totalFromAttachment(attachment);
        if (total <= Duration.zero) {
          total = _totalFromAttachment(attachment);
        }
        if (total <= Duration.zero) {
          total = const Duration(seconds: 1);
        }
        final double progress =
            (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _AudioTimelineBar(
              progress: progress,
              trackBg: trackBg,
              trackFg: trackFg,
              seekable: true,
              onSeekFraction: (double fx) {
                AppHaptics.light();
                final int ms = (total.inMilliseconds * fx.clamp(0.0, 1.0)).round();
                unawaited(ctrl.player.seek(Duration(milliseconds: ms)));
              },
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(fmtDurationFromDuration(pos), style: timeStyle),
                Text(fmtDurationFromDuration(total), style: timeStyle),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AudioTimelineBar extends StatelessWidget {
  const _AudioTimelineBar({
    required this.progress,
    required this.trackBg,
    required this.trackFg,
    required this.seekable,
    required this.onSeekFraction,
  });

  final double progress;
  final Color trackBg;
  final Color trackFg;
  final bool seekable;
  final void Function(double fraction)? onSeekFraction;

  @override
  Widget build(BuildContext context) {
    final Widget bar = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: trackBg,
          valueColor: AlwaysStoppedAnimation<Color>(trackFg),
        ),
      ),
    );

    if (!seekable || onSeekFraction == null) {
      return bar;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails d) {
            final double w = constraints.maxWidth;
            if (w <= 0) {
              return;
            }
            onSeekFraction!(d.localPosition.dx / w);
          },
          child: bar,
        );
      },
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.attachment,
    this.onOpenMessageActions,
  });
  final EventChatAttachment attachment;
  final VoidCallback? onOpenMessageActions;

  IconData _iconForMime(String mime) {
    if (mime.contains('pdf')) return CupertinoIcons.doc_text;
    if (mime.contains('word') || mime.contains('document')) return CupertinoIcons.doc_richtext;
    if (mime.contains('sheet') || mime.contains('excel')) return CupertinoIcons.table;
    if (mime.contains('presentation') || mime.contains('powerpoint')) return CupertinoIcons.rectangle_stack;
    return CupertinoIcons.doc;
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.eventChatOpenFile,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.light();
            unawaited(openChatDocument(context, attachment));
          },
          onLongPress: onOpenMessageActions,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: <Widget>[
                Icon(_iconForMime(attachment.mimeType), size: 32, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eventsChatMessageBody(Theme.of(context).textTheme)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _humanSize(attachment.sizeBytes),
                        style: AppTypography.eventsChatTimestamp(Theme.of(context).textTheme),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.arrow_down_to_line, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Same Carto light raster tiles + cache as [PollutionMapScreen] / [CreateEventSitesMap].
class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.lat,
    required this.lng,
    this.label,
  });

  final double lat;
  final double lng;
  final String? label;

  static final LatLngBounds _cameraBounds = LatLngBounds(
    LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(lat, lng);
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final bool highDpi = dpr > 1.0;

    return Semantics(
      button: true,
      label: '${context.l10n.eventChatLocationMapTitle}. ${label ?? ''}',
      child: Tooltip(
        message: context.l10n.eventChatLocationMapTitle,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppHaptics.light();
              unawaited(openChatLocationFullscreen(context, lat: lat, lng: lng, label: label));
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 140,
                    child: IgnorePointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 15,
                          minZoom: 3,
                          maxZoom: 18,
                          backgroundColor: AppColors.mapLightPaper,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                          cameraConstraint: CameraConstraint.containCenter(bounds: _cameraBounds),
                        ),
                        children: <Widget>[
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const <String>['a', 'b', 'c', 'd'],
                            maxNativeZoom: 20,
                            userAgentPackageName: 'chisto_mobile',
                            retinaMode: highDpi,
                            keepBuffer: 2,
                            panBuffer: 1,
                            tileProvider: createCachedTileProvider(maxStaleDays: 30),
                            tileDisplay: const TileDisplay.fadeIn(
                              duration: Duration(milliseconds: 220),
                              startOpacity: 0,
                            ),
                          ),
                          MarkerLayer(
                            markers: <Marker>[
                              Marker(
                                point: point,
                                width: 40,
                                height: 48,
                                alignment: Alignment.topCenter,
                                child: Icon(
                                  CupertinoIcons.location_solid,
                                  size: 34,
                                  color: AppColors.accentDanger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      left: AppSpacing.xxs,
                      right: AppSpacing.xxs,
                      bottom: 2,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(CupertinoIcons.location, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            (label != null && label!.trim().isNotEmpty)
                                ? label!.trim()
                                : context.l10n.eventsDetailOpenInMaps,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.eventsGridPropertyValue(Theme.of(context).textTheme),
                          ),
                        ),
                        Icon(Icons.open_in_new, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
