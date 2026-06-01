library;

import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/cached_tile_provider.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_document_open_flow.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_image_gallery_screen.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_linkified_text.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_location_fullscreen_screen.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_message_action_row.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_message_bubble_image_tile.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_theme.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_video_player_screen.dart';
import 'package:feature_events/src/presentation/widgets/chat/event_chat_audio_playback_scope.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:latlong2/latlong.dart';

part 'chat_message_bubble_actions.dart';
part 'chat_message_bubble_attachments.dart';

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
    this.onAuthorBlocked,
    required this.downloadRemoteAttachment,
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

  /// Called after the peer author was blocked (remove their messages locally).
  final void Function(String authorId)? onAuthorBlocked;

  final Future<Uint8List> Function(String url) downloadRemoteAttachment;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with TickerProviderStateMixin, _ChatMessageBubbleActionsMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;
  late final AnimationController _pulseController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    final bool own = widget.message.isOwnMessage;
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.chatBubbleEntrance,
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.chatBubbleEntranceCurve,
    );
    _entranceSlide =
        Tween<Offset>(
          begin: Offset(own ? 0.12 : -0.12, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: AppMotion.chatBubbleEntranceCurve,
          ),
        );
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
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
    final String timeStr = DateFormat.jm(
      Localizations.localeOf(context).toString(),
    ).format(m.createdAt.toLocal());
    final String bodyText = m.isDeleted
        ? context.l10n.eventChatMessageRemoved
        : (m.body ?? '');
    final String semBody = m.isDeleted ? bodyText : (m.body ?? '');
    String semanticsLabel = context.l10n.eventChatSemanticsBubble(
      m.authorName,
      timeStr,
      semBody,
    );
    if (widget.receiptSeenByLine != null &&
        widget.receiptSeenByLine!.isNotEmpty) {
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
        ? ChatTheme.highlightBorder(highlighted: true)
        : m.isDeleted
        ? AppColors.transparent
        : ChatTheme.bubbleNormalBorder(own: own);
    final double borderWidth = m.isDeleted
        ? 0
        : (m.failed
              ? 1
              : ChatTheme.highlightBorderWidth(
                  highlighted: widget.highlighted,
                ));

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
                  if (own)
                    ...ChatTheme.bubbleOwnShadow
                  else
                    ...ChatTheme.bubblePeerShadow,
                  if (widget.highlighted)
                    ...ChatTheme.highlightPulse(_pulseController.value),
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
                            widget.onRetry?.call();
                          }
                        : null,
                    onLongPress: (m.isDeleted || m.pending)
                        ? null
                        : () {
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
          const SizedBox(width: ChatTheme.avatarGap),
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
    final TextStyle metaStyle = AppTypography.eventsChatTimestamp(
      textTheme,
      color: ChatTheme.metaText,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.showAuthorName && !own) ...<Widget>[
          Text(
            m.authorName,
            style: AppTypography.eventsChatAuthorName(
              textTheme,
            ).copyWith(color: ChatTheme.avatarColor(m.authorId)),
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
            padding: EdgeInsets.only(
              bottom: (m.body != null && m.body!.isNotEmpty)
                  ? AppSpacing.xs
                  : 0,
            ),
            child: _buildMediaContent(context, m, own),
          ),
        if (m.messageType == EventChatMessageType.location &&
            !m.isDeleted &&
            m.locationLat != null &&
            m.locationLng != null)
          Padding(
            padding: EdgeInsets.only(
              bottom: (m.body != null && m.body!.isNotEmpty)
                  ? AppSpacing.xs
                  : 0,
            ),
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
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.accentDanger,
                  ),
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
            ).copyWith(fontStyle: FontStyle.italic),
          )
        else if (m.body != null && m.body!.isNotEmpty)
          ChatLinkifiedText(
            text: m.body!,
            style: AppTypography.eventsChatMessageBody(textTheme, color: fg),
          ),
        if (m.pending)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.insetTight),
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
                    borderRadius: AppRadii.chatMicro,
                    child: AppLinearProgress(
                      value: widget.uploadFraction!.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: ChatTheme.replyQuoteFill,
                      valueColor: AppColors.primary,
                    ),
                  ),
                  if (widget.onCancelUpload != null)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppButton.text(
                        label: context.l10n.commonCancel,
                        onPressed: widget.onCancelUpload,
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

  VoidCallback? _mediaMessageActionsCallback(
    BuildContext context,
    EventChatMessage m,
  ) {
    final bool canOpen = !m.isDeleted && !m.pending && _hasAnyMessageAction(m);
    if (!canOpen) {
      return null;
    }
    return () {
      unawaited(_showActions(context));
    };
  }

  Widget _buildMediaContent(
    BuildContext context,
    EventChatMessage m,
    bool own,
  ) {
    final String mime = m.attachments.first.mimeType.toLowerCase();
    if (mime.startsWith('video/')) {
      return _VideoPreview(
        attachment: m.attachments.first,
        onOpenMessageActions: _mediaMessageActionsCallback(context, m),
      );
    }
    if (mime.startsWith('audio/')) {
      final bool canOpenActions =
          !m.isDeleted && !m.pending && _hasAnyMessageAction(m);
      return _ChatAudioInline(
        clipKey: m.id,
        attachment: m.attachments.first,
        own: own,
        onOpenMessageActions: canOpenActions
            ? () {
                unawaited(_showActions(context));
              }
            : null,
      );
    }
    if (mime.startsWith('application/') || mime.startsWith('text/')) {
      return _DocumentPreview(
        attachment: m.attachments.first,
        onOpenMessageActions: _mediaMessageActionsCallback(context, m),
        downloadRemote: widget.downloadRemoteAttachment,
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
      padding: const EdgeInsets.only(top: AppSpacing.insetTight),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: own
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          if (m.editedAt != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xxs),
              child: Text(context.l10n.eventChatEdited, style: metaStyle),
            ),
          if (m.isPinned)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 3),
              child: Icon(
                CupertinoIcons.pin,
                size: 10,
                color: ChatTheme.metaText,
              ),
            ),
          Text(
            timeStr,
            style: metaStyle,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.34),
          ),
          if (own && !m.isDeleted && m.messageType == EventChatMessageType.text)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 3),
              child: Icon(
                widget.receiptSeenByLine != null ? Icons.done_all : Icons.done,
                size: 14,
                color:
                    widget.receiptSeenByLine != null &&
                        widget.receiptAllPeersRead
                    ? AppColors.primary
                    : ChatTheme.metaText,
              ),
            ),
        ],
      ),
    );
  }
}
