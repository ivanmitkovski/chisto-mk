import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/presentation/mic_permission_ui.dart';
import 'package:feature_events/src/presentation/utils/events_diagnostic_log.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_input_bar_attach_option_row.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_theme.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_voice_recorder.dart';
import 'package:feature_events/src/presentation/widgets/chat/voice_recording_meter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

part 'chat_input_bar_attachments.dart';
part 'chat_input_bar_voice.dart';

/// One-time in-app rationale before the OS microphone prompt (parity with push flow).
const String kEventChatMicRationaleCompletedKey =
    'event_chat_mic_rationale_completed_v1';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    @visibleForTesting this.voiceRecorder,
    this.composerFocusNode,
    this.replyTo,
    this.onCancelReply,
    this.editingMessage,
    this.onCancelEdit,
    this.onComposerTextChanged,
    this.onComposerSendCompleted,
    this.onSendImages,
    this.onSendVoice,
    this.onShareLocation,
    this.attachmentsNeedNetwork = false,
  });

  final Future<void> Function(String text) onSend;
  @visibleForTesting
  final ChatVoiceRecorder? voiceRecorder;

  /// When set, the screen owns the node (e.g. to focus from an empty-state CTA).
  final FocusNode? composerFocusNode;
  final EventChatMessage? replyTo;
  final VoidCallback? onCancelReply;
  final EventChatMessage? editingMessage;
  final VoidCallback? onCancelEdit;
  final ValueChanged<String>? onComposerTextChanged;
  final VoidCallback? onComposerSendCompleted;
  final Future<void> Function(List<XFile> files)? onSendImages;

  /// When set, releasing the mic opens a review row (X / Send) instead of sending immediately.
  final Future<void> Function(XFile file, Duration recordedLength)? onSendVoice;
  final VoidCallback? onShareLocation;

  /// When true, blocks attachment / voice flows that require upload (text-only offline queue remains available).
  final bool attachmentsNeedNetwork;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        _ChatInputBarVoiceMixin {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  late final bool _ownsComposerFocus;
  late final AnimationController _sendAnim;
  bool _sending = false;
  final List<XFile> _stagedImages = <XFile>[];
  final ImagePicker _picker = ImagePicker();

  @override
  bool get _composerBusy => _sending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.composerFocusNode != null) {
      _focusNode = widget.composerFocusNode!;
      _ownsComposerFocus = false;
    } else {
      _focusNode = FocusNode();
      _ownsComposerFocus = true;
    }
    _sendAnim = AnimationController(vsync: this, duration: AppMotion.xFast);
    if (widget.editingMessage != null) {
      _controller.text = widget.editingMessage!.body ?? '';
    }
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != null &&
        widget.editingMessage!.id != oldWidget.editingMessage?.id) {
      _controller.text = widget.editingMessage!.body ?? '';
    }
    if (widget.editingMessage == null && oldWidget.editingMessage != null) {
      _controller.clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onVoiceAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeVoiceSide();
    _controller.dispose();
    if (_ownsComposerFocus) {
      _focusNode.dispose();
    }
    _sendAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int len = _controller.text.characters.length;
    final bool showCount = len >= 1800;
    final bool nearLimit = len >= 1950;
    final bool dangerLimit = len >= 1950;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(height: 0.5, color: AppColors.divider.withValues(alpha: 0.3)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            boxShadow: AppShadows.chatComposerLift(),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedSize(
                    duration: AppMotion.fast,
                    curve: AppMotion.emphasized,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: AppMotion.standard,
                      switchInCurve: AppMotion.smooth,
                      switchOutCurve: AppMotion.sharpDecelerate,
                      layoutBuilder: (Widget? current, List<Widget> previous) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: <Widget>[...previous, ?current],
                        );
                      },
                      transitionBuilder:
                          (Widget child, Animation<double> anim) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.1),
                                end: Offset.zero,
                              ).animate(anim),
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            );
                          },
                      child: _buildBanner(context),
                    ),
                  ),
                  if (_voiceReviewFile != null && widget.onSendVoice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildVoiceReviewRow(context),
                    ),
                  if (_voiceRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildVoiceRecordingPanel(context),
                    ),
                  if (_stagedImages.isNotEmpty) _buildThumbnailStrip(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (widget.editingMessage == null &&
                          widget.onSendImages != null) ...<Widget>[
                        GestureDetector(
                          onTap: () {
                            if (_mediaBlockedByNetwork()) {
                              return;
                            }
                            _showAttachmentMenu();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                              right: AppSpacing.xs,
                            ),
                            child: Icon(
                              CupertinoIcons.plus_circle_fill,
                              size: 28,
                              color: AppColors.primary.withValues(
                                alpha: widget.attachmentsNeedNetwork
                                    ? 0.35
                                    : 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: AnimatedSize(
                          duration: AppMotion.fast,
                          curve: AppMotion.emphasized,
                          alignment: Alignment.bottomCenter,
                          child: Semantics(
                            label: widget.editingMessage != null
                                ? context.l10n.eventChatEditHint
                                : context.l10n.eventChatInputSemantics,
                            child: EventsChatComposerField(
                              controller: _controller,
                              focusNode: _focusNode,
                              hintText: widget.editingMessage != null
                                  ? context.l10n.eventChatEditHint
                                  : context.l10n.eventChatInputHint,
                              onChanged: (String v) {
                                setState(() {});
                                widget.onComposerTextChanged?.call(v);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildTrailingAction(context),
                    ],
                  ),
                  if (showCount)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.xxs,
                        left: AppSpacing.md,
                      ),
                      child: Text(
                        context.l10n.eventChatCharCountHint(len),
                        style: AppTypography.eventsCaptionStrong(
                          Theme.of(context).textTheme,
                          color: dangerLimit
                              ? AppColors.error
                              : nearLimit
                              ? AppColors.accentWarning
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    if (widget.editingMessage != null) {
      return KeyedSubtree(
        key: ValueKey<String>('edit-${widget.editingMessage!.id}'),
        child: _replyEditBanner(
          context,
          label: context.l10n.eventChatEditing,
          preview: widget.editingMessage!.body,
          onCancel: widget.onCancelEdit,
        ),
      );
    }
    if (widget.replyTo != null) {
      return KeyedSubtree(
        key: ValueKey<String>('reply-${widget.replyTo!.id}'),
        child: _replyEditBanner(
          context,
          label: context.l10n.eventChatReplyingTo(widget.replyTo!.authorName),
          preview: widget.replyTo!.body,
          onCancel: widget.onCancelReply,
        ),
      );
    }
    return const KeyedSubtree(
      key: ValueKey<String>('banner-none'),
      child: SizedBox.shrink(),
    );
  }

  Widget _replyEditBanner(
    BuildContext context, {
    required String label,
    required String? preview,
    required VoidCallback? onCancel,
  }) {
    final String text = (preview ?? '').trim();
    final String previewLine = text.length > 50
        ? '${text.substring(0, 50)}…'
        : text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          0,
          AppSpacing.sm - 2,
          AppSpacing.sm,
          AppSpacing.sm - 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: BorderDirectional(
            start: BorderSide(width: 3, color: ChatTheme.replyQuoteBar),
          ),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.eventsSheetTextLink(
                      Theme.of(context).textTheme,
                    ).copyWith(color: AppColors.primary),
                  ),
                  if (previewLine.isNotEmpty)
                    Text(
                      previewLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.eventsCalloutSubtitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onCancel,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.xxs),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool _mediaBlockedByNetwork() {
    if (!widget.attachmentsNeedNetwork) {
      return false;
    }
    if (!mounted) {
      return true;
    }
    AppSnack.show(
      context,
      message: context.l10n.eventChatAttachmentsNeedNetwork,
    );
    return true;
  }

  Widget _buildTrailingAction(BuildContext context) {
    final bool canSend =
        !_sending && (_trimmed.isNotEmpty || _stagedImages.isNotEmpty);
    final Widget? voiceAction = _buildVoiceTrailingAction(
      context,
      canSend: canSend,
    );
    if (voiceAction != null) {
      return voiceAction;
    }
    return _buildSendButton(context, canSend: canSend);
  }

  Widget _buildSendButton(BuildContext context, {required bool canSend}) {
    return AnimatedScale(
      scale: canSend ? 1.0 : 0.9,
      duration: AppMotion.fast,
      curve: AppMotion.smooth,
      child: Semantics(
        button: true,
        label: widget.editingMessage != null
            ? context.l10n.eventChatSaveEdit
            : context.l10n.eventChatSend,
        child: SizedBox(
          height: 44,
          width: 44,
          child: AnimatedBuilder(
            animation: _sendAnim,
            builder: (BuildContext context, Widget? child) {
              final double rot = _sendAnim.value * 0.5;
              final double scale = 1.0 - _sendAnim.value * 0.15;
              return Transform.rotate(
                angle: -rot,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: canSend && !_sending ? _submit : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: canSend ? AppColors.primary : AppColors.inputFill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _sending
                      ? const AppLoadingIndicator(
                          size: AppLoadingIndicatorSize.sm,
                          color: AppColors.textOnDark,
                        )
                      : Icon(
                          widget.editingMessage != null
                              ? CupertinoIcons.check_mark
                              : CupertinoIcons.arrow_up,
                          size: 20,
                          color: _trimmed.isEmpty
                              ? AppColors.textMuted
                              : AppColors.textOnDark,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _trimmed => _controller.text.trim();

  Future<void> _submit() async {
    final String t = _trimmed;
    final bool hasImages = _stagedImages.isNotEmpty;
    if (t.isEmpty && !hasImages) return;
    if (_sending) return;
    setState(() => _sending = true);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      unawaited(_sendAnim.forward().then((_) => _sendAnim.reverse()));
    }
    try {
      if (hasImages && widget.onSendImages != null) {
        final List<XFile> toSend = List<XFile>.from(_stagedImages);
        _stagedImages.clear();
        await widget.onSendImages!(toSend);
      }
      if (t.isNotEmpty) {
        await widget.onSend(t);
      }
      if (mounted) {
        if (widget.editingMessage == null) _controller.clear();
        _focusNode.requestFocus();
        setState(() {});
        widget.onComposerSendCompleted?.call();
      }
    } on Object catch (_) {
      // Error surfaced by parent / snack
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
