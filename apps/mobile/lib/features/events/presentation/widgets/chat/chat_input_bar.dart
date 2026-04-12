import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/voice_recording_meter.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.replyTo,
    this.onCancelReply,
    this.editingMessage,
    this.onCancelEdit,
    this.onComposerTextChanged,
    this.onComposerSendCompleted,
    this.onSendImages,
    this.onSendVoice,
    this.onShareLocation,
  });

  final Future<void> Function(String text) onSend;
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

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> with SingleTickerProviderStateMixin {
  /// Pull this far left from the mic (horizontal) before cancel arms — avoids tiny wobble.
  static const double _kVoiceCancelEnterPx = 160;
  /// While cancelling, move this far back toward the mic before we leave cancel (hysteresis).
  static const double _kVoiceCancelReleasePx = 112;
  /// Shorter than [kLongPressTimeout] so recording starts closer to iMessage.
  static const Duration _kVoiceLongPressDuration = Duration(milliseconds: 200);
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _sendAnim;
  bool _sending = false;
  final List<XFile> _stagedImages = <XFile>[];
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _voiceRecorder = AudioRecorder();
  bool _voiceRecording = false;
  bool _voiceCancelled = false;
  /// True while the user’s finger is down on the mic long-press (set synchronously).
  bool _voicePressHeld = false;
  Timer? _voiceMaxTimer;
  Timer? _voiceDurationTimer;
  DateTime? _voiceRecordStartedAt;
  String? _voicePath;
  XFile? _voiceReviewFile;
  Duration _voiceReviewLength = Duration.zero;
  bool _sendingVoiceReview = false;
  /// Horizontal drag from long-press origin (negative = sliding toward cancel).
  double _voicePanDx = 0;

  bool get _voiceAttachAvailable =>
      widget.onSendVoice != null || widget.onSendImages != null;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _voiceMaxTimer?.cancel();
    _stopVoiceDurationUi();
    unawaited(_voiceRecorder.dispose());
    _controller.dispose();
    _focusNode.dispose();
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
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
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
                          children: <Widget>[
                            ...previous,
                            if (current != null) current,
                          ],
                        );
                      },
                      transitionBuilder: (Widget child, Animation<double> anim) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.1),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
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
                  if (_stagedImages.isNotEmpty)
                    _buildThumbnailStrip(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (widget.editingMessage == null && widget.onSendImages != null) ...<Widget>[
                        GestureDetector(
                          onTap: _showAttachmentMenu,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10, right: AppSpacing.xs),
                            child: Icon(
                              CupertinoIcons.plus_circle_fill,
                              size: 28,
                              color: AppColors.primary.withValues(alpha: 0.75),
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
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: widget.editingMessage != null
                                    ? context.l10n.eventChatEditHint
                                    : context.l10n.eventChatInputHint,
                                filled: true,
                                fillColor: AppColors.inputFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorder.withValues(alpha: 0.35),
                                    width: 0.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorder.withValues(alpha: 0.35),
                                    width: 0.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                isDense: true,
                              ),
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
                      padding: const EdgeInsets.only(top: AppSpacing.xxs, left: AppSpacing.md),
                      child: Text(
                        context.l10n.eventChatCharCountHint(len),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: dangerLimit
                                  ? AppColors.accentDanger
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
    final String previewLine = text.length > 50 ? '${text.substring(0, 50)}…' : text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm - 2, AppSpacing.sm, AppSpacing.sm - 2),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                  ),
                  if (previewLine.isNotEmpty)
                    Text(
                      previewLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onCancel,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVoiceDuration(Duration d) {
    final int sec = d.inSeconds.clamp(0, 35999);
    final int m = sec ~/ 60;
    final int s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildVoiceReviewRow(BuildContext context) {
    final XFile? file = _voiceReviewFile;
    if (file == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: BorderDirectional(
          start: BorderSide(width: 3, color: AppColors.primary.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: context.l10n.eventChatVoiceDiscard,
            child: GestureDetector(
              onTap: _sendingVoiceReview ? null : _discardVoiceReview,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Icon(CupertinoIcons.xmark_circle_fill, size: 22, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.l10n.eventChatVoicePreviewHint,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                ),
                Text(
                  _formatVoiceDuration(_voiceReviewLength),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: context.l10n.eventChatVoiceSend,
            child: FilledButton(
              onPressed: _sendingVoiceReview ? null : () => unawaited(_submitVoiceReview()),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                maximumSize: const Size(44, 44),
                shape: const CircleBorder(),
                backgroundColor: AppColors.primary,
              ),
              child: _sendingVoiceReview
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnDark),
                    )
                  : const Icon(CupertinoIcons.arrow_up, size: 20, color: AppColors.textOnDark),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _discardVoiceReview() async {
    final XFile? f = _voiceReviewFile;
    if (f == null) {
      return;
    }
    AppHaptics.light(context);
    setState(() {
      _voiceReviewFile = null;
      _voiceReviewLength = Duration.zero;
    });
    try {
      await File(f.path).delete();
    } on Object {
      // ignore
    }
  }

  Future<void> _submitVoiceReview() async {
    final XFile? f = _voiceReviewFile;
    final Future<void> Function(XFile file, Duration recordedLength)? cb = widget.onSendVoice;
    if (f == null || cb == null || _sendingVoiceReview) {
      return;
    }
    setState(() => _sendingVoiceReview = true);
    AppHaptics.tap();
    final String path = f.path;
    try {
      await cb(f, _voiceReviewLength);
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceReviewFile = null;
        _voiceReviewLength = Duration.zero;
        _sendingVoiceReview = false;
      });
      try {
        await File(path).delete();
      } on Object {
        // ignore
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _sendingVoiceReview = false);
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
      }
    }
  }

  Widget _buildVoiceRecordingPanel(BuildContext context) {
    final double pull = math.max(0.0, -_voicePanDx);
    final double cancelT = (pull / _kVoiceCancelEnterPx).clamp(0.0, 1.0);
    final Color danger = AppColors.accentDanger;
    final Color baseFill = AppColors.inputFill;
    final Color bgColor = Color.lerp(
      baseFill,
      danger.withValues(alpha: 0.12),
      _voiceCancelled ? 1.0 : cancelT * 0.88,
    )!;
    final Color borderColor = Color.lerp(
      AppColors.inputBorder.withValues(alpha: 0.35),
      danger,
      _voiceCancelled ? 1.0 : cancelT,
    )!;
    final double borderWidth = _voiceCancelled ? 2 : (cancelT > 0.06 ? 1 + cancelT * 0.6 : 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
        boxShadow: _voiceCancelled
            ? <BoxShadow>[
                BoxShadow(
                  color: danger.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 26,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: 0.4 + 0.55 * cancelT,
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      size: 20,
                      color: Color.lerp(AppColors.textMuted, danger, cancelT),
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: _voiceCancelled ? 1.1 : 1.0 + 0.06 * cancelT,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    _voiceCancelled ? CupertinoIcons.xmark_circle_fill : CupertinoIcons.mic_fill,
                    color: _voiceCancelled ? danger : Color.lerp(AppColors.primary, danger, cancelT),
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Transform.translate(
                    offset: Offset(math.min(0, _voicePanDx * 0.12), 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          height: VoiceRecordingMeter.maxBarHeight + 2,
                          child: VoiceRecordingMeter(
                            recorder: _voiceRecorder,
                            active: _voiceRecording,
                            cancelled: _voiceCancelled,
                            reduceMotion: MediaQuery.disableAnimationsOf(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Semantics(
                          container: true,
                          label: _voiceCancelled
                              ? '${context.l10n.eventChatReleaseToCancel}. ${context.l10n.eventChatVoiceDiscard}'
                              : '${context.l10n.eventChatRecording} ${context.l10n.eventChatSlideToCancel}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _voiceCancelled
                                    ? context.l10n.eventChatReleaseToCancel
                                    : context.l10n.eventChatRecording,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: _voiceCancelled ? danger : AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                              if (!_voiceCancelled)
                                Text(
                                  context.l10n.eventChatSlideToCancel,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.textMuted,
                                        height: 1.25,
                                      ),
                                )
                              else
                                Text(
                                  context.l10n.eventChatVoiceDiscard,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: danger.withValues(alpha: 0.88),
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _voiceRecordingDurationLabel(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                        color: _voiceCancelled ? danger : AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            if (cancelT > 0.04 && !_voiceCancelled)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: cancelT,
                    minHeight: 3,
                    backgroundColor: AppColors.divider.withValues(alpha: 0.4),
                    color: danger.withValues(alpha: 0.45 + 0.45 * cancelT),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingAction(BuildContext context) {
    final bool canSend = !_sending && (_trimmed.isNotEmpty || _stagedImages.isNotEmpty);
    final bool showVoiceMic = !canSend &&
        _voiceReviewFile == null &&
        _voiceAttachAvailable &&
        widget.editingMessage == null;
    if (showVoiceMic) {
      return _buildVoiceMicButton(context);
    }
    if (_voiceReviewFile != null && widget.onSendVoice != null) {
      return const SizedBox(width: 44, height: 44);
    }
    return _buildSendButton(context, canSend: canSend);
  }

  Widget _buildVoiceMicButton(BuildContext context) {
    return AnimatedScale(
      scale: _voiceRecording ? 0.95 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.smooth,
      child: Semantics(
        button: true,
        label: context.l10n.eventChatHoldToRecord,
        child: SizedBox(
          height: 44,
          width: 44,
          child: Material(
            color: _voiceRecording
                ? AppColors.accentDanger.withValues(alpha: 0.12)
                : AppColors.inputFill,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer(duration: _kVoiceLongPressDuration),
                  (LongPressGestureRecognizer instance) {
                    instance
                      ..onLongPressStart = _onVoiceLongPressStart
                      ..onLongPressMoveUpdate = _onVoiceLongPressMoveUpdate
                      ..onLongPressEnd = _onVoiceLongPressEndFromGesture
                      ..onLongPressCancel = _onVoiceLongPressGestureCancel;
                  },
                ),
              },
              // Fill the 44×44 circle so long-press isn’t limited to the icon’s intrinsic ~22px box.
              child: SizedBox.expand(
                child: Center(
                  child: Icon(
                    CupertinoIcons.mic_fill,
                    size: 22,
                    color: _voiceRecording
                        ? AppColors.accentDanger.withValues(alpha: 0.95)
                        : AppColors.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
            child: FilledButton(
              onPressed: canSend ? _submit : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.inputFill,
                disabledForegroundColor: AppColors.textMuted,
                foregroundColor: AppColors.textOnDark,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnDark),
                    )
                  : Icon(
                      widget.editingMessage != null
                          ? CupertinoIcons.check_mark
                          : CupertinoIcons.arrow_up,
                      size: 20,
                      color: _trimmed.isEmpty ? AppColors.textMuted : AppColors.textOnDark,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _onVoiceLongPressEndFromGesture(LongPressEndDetails details) {
    unawaited(_onVoiceLongPressEnd());
  }

  void _onVoiceLongPressGestureCancel() {
    _voicePressHeld = false;
  }

  void _onVoiceLongPressStart(LongPressStartDetails details) {
    if (!_voiceAttachAvailable || _sending || _voiceReviewFile != null) {
      return;
    }
    _voicePressHeld = true;
    _voiceCancelled = false;
    _voicePanDx = 0;
    unawaited(_beginVoiceRecording());
  }

  Future<void> _beginVoiceRecording() async {
    if (!_voiceAttachAvailable || _sending || _voiceReviewFile != null) {
      _voicePressHeld = false;
      return;
    }
    final PermissionStatus st = await Permission.microphone.request();
    if (!st.isGranted) {
      _voicePressHeld = false;
      if (mounted) {
        AppSnack.show(context, message: context.l10n.eventChatMicPermissionDenied);
        if (Platform.isIOS && st.isPermanentlyDenied) {
          await openAppSettings();
        }
      }
      return;
    }
    if (!await _voiceRecorder.hasPermission()) {
      _voicePressHeld = false;
      if (mounted) {
        AppSnack.show(context, message: context.l10n.eventChatMicPermissionDenied);
      }
      return;
    }
    if (!_voicePressHeld) {
      return;
    }
    final Directory dir = await getTemporaryDirectory();
    if (!_voicePressHeld) {
      return;
    }
    final String path = '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    _voicePath = path;
    try {
      // Favor raw-ish levels for the meter (less AGC/DSP) and legacy MediaRecorder on
      // Android so getAmplitude / onAmplitudeChanged are more likely to move the strip.
      await _voiceRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          noiseSuppress: false,
          echoCancel: false,
          autoGain: false,
          androidConfig: Platform.isAndroid
              ? const AndroidRecordConfig(useLegacy: true)
              : const AndroidRecordConfig(),
        ),
        path: path,
      );
    } on Object {
      _voicePressHeld = false;
      _voicePath = null;
      if (mounted) {
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
      }
      return;
    }
    if (!_voicePressHeld) {
      await _discardVoiceCapture(deleteFile: true);
      return;
    }
    _voiceCancelled = false;
    _voiceMaxTimer?.cancel();
    _voiceMaxTimer = Timer(const Duration(minutes: 3), () {
      unawaited(_onVoiceLongPressEnd(forceSend: true));
    });
    _voiceRecording = true;
    _startVoiceDurationUi();
    if (mounted) {
      AppHaptics.medium(context);
      setState(() {});
    }
  }

  void _startVoiceDurationUi() {
    _voiceDurationTimer?.cancel();
    _voiceRecordStartedAt = DateTime.now();
    _voiceDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stopVoiceDurationUi() {
    _voiceDurationTimer?.cancel();
    _voiceDurationTimer = null;
    _voiceRecordStartedAt = null;
  }

  String _voiceRecordingDurationLabel() {
    final DateTime? start = _voiceRecordStartedAt;
    if (start == null) {
      return '0:00';
    }
    final int sec = DateTime.now().difference(start).inSeconds.clamp(0, 35999);
    final int m = sec ~/ 60;
    final int s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Stops/cancels recorder and optionally deletes [_voicePath].
  Future<void> _discardVoiceCapture({required bool deleteFile}) async {
    try {
      await _voiceRecorder.cancel();
    } on Object {
      try {
        await _voiceRecorder.stop();
      } on Object {
        // Recording may already be stopped.
      }
    }
    final String? path = _voicePath;
    _voicePath = null;
    if (deleteFile && path != null) {
      try {
        await File(path).delete();
      } on Object {
        // ignore
      }
    }
    _stopVoiceDurationUi();
    if (mounted) {
      setState(() {
        _voiceRecording = false;
        _voiceCancelled = false;
        _voicePanDx = 0;
      });
    } else {
      _voiceRecording = false;
      _voiceCancelled = false;
      _voicePanDx = 0;
    }
  }

  void _onVoiceLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_voiceRecording) {
      return;
    }
    final double dx = details.localOffsetFromOrigin.dx;
    final bool wasCancelled = _voiceCancelled;
    final bool cancel = wasCancelled
        ? dx < -_kVoiceCancelReleasePx
        : dx < -_kVoiceCancelEnterPx;
    if (cancel != wasCancelled) {
      AppHaptics.light(context);
    }
    setState(() {
      _voicePanDx = dx;
      _voiceCancelled = cancel;
    });
  }

  Future<void> _onVoiceLongPressEnd({bool forceSend = false}) async {
    _voiceMaxTimer?.cancel();
    _voiceMaxTimer = null;
    _voicePressHeld = false;

    final bool hardwareRecording = await _voiceRecorder.isRecording();
    if (!_voiceRecording && !hardwareRecording) {
      return;
    }

    final String? pathBeforeStop = _voicePath;
    final DateTime? recordStartedAt = _voiceRecordStartedAt;
    final bool send =
        pathBeforeStop != null && _voiceAttachAvailable && (forceSend || !_voiceCancelled);
    String? pathForUpload = pathBeforeStop;
    try {
      if (_voiceCancelled && !forceSend) {
        await _voiceRecorder.cancel();
        pathForUpload = null;
      } else {
        final String? stoppedPath = await _voiceRecorder.stop();
        pathForUpload = stoppedPath ?? pathBeforeStop;
      }
    } on Object {
      // Recording may already be stopped.
    }
    _voicePath = null;
    _stopVoiceDurationUi();
    if (mounted) {
      setState(() {
        _voiceRecording = false;
        _voiceCancelled = false;
        _voicePanDx = 0;
      });
    } else {
      _voiceRecording = false;
      _voiceCancelled = false;
      _voicePanDx = 0;
    }
    final String? pathToDelete = pathForUpload ?? pathBeforeStop;
    if (send && mounted && pathForUpload != null) {
      // Local for use inside [setState]: promotion does not apply inside the closure.
      final String uploadPath = pathForUpload;
      if (widget.onSendVoice != null) {
        final Duration recorded = recordStartedAt != null
            ? DateTime.now().difference(recordStartedAt)
            : Duration.zero;
        setState(() {
          _voiceReviewFile = XFile(uploadPath, name: 'voice.m4a');
          _voiceReviewLength = recorded < Duration.zero ? Duration.zero : recorded;
        });
        AppHaptics.light(context);
      } else {
        try {
          await widget.onSendImages!(<XFile>[XFile(uploadPath, name: 'voice.m4a')]);
        } on Object catch (_) {
          if (mounted) {
            AppSnack.show(context, message: context.l10n.eventChatSendFailed);
          }
        }
        try {
          await File(uploadPath).delete();
        } on Object {
          // ignore
        }
      }
    } else if (pathToDelete != null) {
      try {
        await File(pathToDelete).delete();
      } on Object {
        // ignore
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet<void>(
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
              _AttachOptionRow(
                icon: CupertinoIcons.photo,
                label: context.l10n.eventChatAttachPhotoLibrary,
                onTap: () { Navigator.pop(ctx); _pickImages(ImageSource.gallery); },
              ),
              _AttachOptionRow(
                icon: CupertinoIcons.camera,
                label: context.l10n.eventChatAttachCamera,
                onTap: () { Navigator.pop(ctx); _pickImages(ImageSource.camera); },
              ),
              _AttachOptionRow(
                icon: CupertinoIcons.videocam,
                label: context.l10n.eventChatAttachVideo,
                onTap: () { Navigator.pop(ctx); _pickVideo(); },
              ),
              _AttachOptionRow(
                icon: CupertinoIcons.doc,
                label: context.l10n.eventChatAttachDocument,
                onTap: () { Navigator.pop(ctx); _pickDocument(); },
              ),
              _AttachOptionRow(
                icon: CupertinoIcons.music_note,
                label: context.l10n.eventChatAttachAudio,
                onTap: () { Navigator.pop(ctx); _pickAudio(); },
              ),
              if (widget.onShareLocation != null)
                _AttachOptionRow(
                  icon: CupertinoIcons.location,
                  label: context.l10n.eventChatAttachLocation,
                  onTap: () { Navigator.pop(ctx); widget.onShareLocation!(); },
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null || !mounted) return;
      if (widget.onSendImages != null) {
        await widget.onSendImages!(<XFile>[video]);
      }
    } on Object catch (_) {}
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final PlatformFile pf = result.files.first;
      if (pf.path == null) return;
      if (widget.onSendImages != null) {
        await widget.onSendImages!(<XFile>[XFile(pf.path!, name: pf.name)]);
      }
    } on Object catch (_) {}
  }

  Future<void> _pickAudio() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['mp3', 'aac', 'm4a', 'ogg', 'wav'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final PlatformFile pf = result.files.first;
      if (pf.path == null) return;
      if (widget.onSendImages != null) {
        await widget.onSendImages!(<XFile>[XFile(pf.path!, name: pf.name)]);
      }
    } on Object catch (_) {}
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(limit: 5);
        if (images.isEmpty) return;
        setState(() {
          _stagedImages.addAll(images.take(5 - _stagedImages.length));
        });
      } else {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo == null) return;
        setState(() {
          if (_stagedImages.length < 5) _stagedImages.add(photo);
        });
      }
    } on Object catch (_) {}
  }

  Widget _buildThumbnailStrip() {
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _stagedImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (BuildContext context, int i) {
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: FutureBuilder<Uint8List>(
                      future: _stagedImages[i].readAsBytes(),
                      builder: (BuildContext ctx, AsyncSnapshot<Uint8List> snap) {
                        if (snap.hasData) {
                          return Image.memory(
                            snap.data!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container(
                          width: 72,
                          height: 72,
                          color: AppColors.inputFill,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => setState(() => _stagedImages.removeAt(i)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.appBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
    AppHaptics.success(context);
    setState(() => _sending = true);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      _sendAnim.forward().then((_) => _sendAnim.reverse());
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

class _AttachOptionRow extends StatelessWidget {
  const _AttachOptionRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
