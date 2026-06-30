part of 'package:feature_events/src/presentation/widgets/chat/chat_input_bar.dart';

/// Voice recording UI, gesture handlers, and mic lifecycle for [ChatInputBar].
mixin _ChatInputBarVoiceMixin
    on ConsumerState<ChatInputBar>, WidgetsBindingObserver {
  /// Pull this far left from the mic (horizontal) before cancel arms — avoids tiny wobble.
  static const double _kVoiceCancelEnterPx = 160;

  /// While cancelling, move this far back toward the mic before we leave cancel (hysteresis).
  static const double _kVoiceCancelReleasePx = 112;

  /// Shorter than [kLongPressTimeout] so recording starts closer to iMessage.
  static const Duration _kVoiceLongPressDuration = Duration(milliseconds: 200);

  late final ChatVoiceRecorder _voiceRecorder =
      widget.voiceRecorder ?? PackageChatVoiceRecorder();
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
  bool _voiceDisposed = false;

  /// Cached fallback recorder for the meter when [widget.voiceRecorder] is not
  /// a [PackageChatVoiceRecorder] (test seam). Created lazily so production
  /// builds (which always inject [PackageChatVoiceRecorder]) skip it entirely.
  AudioRecorder? _fallbackMeterRecorder;

  bool get _voiceAttachAvailable =>
      widget.onSendVoice != null || widget.onSendImages != null;

  bool get _composerBusy;

  void onVoiceAppLifecycleState(AppLifecycleState state) {
    // Do not tear down on [inactive] — iOS shows the mic permission sheet as inactive.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_teardownVoiceRecording());
    }
  }

  void disposeVoiceSide() {
    _voiceDisposed = true;
    _voiceMaxTimer?.cancel();
    _voiceMaxTimer = null;
    _stopVoiceDurationUi();
    final ChatVoiceRecorder recorder = _voiceRecorder;
    final AudioRecorder? fallback = _fallbackMeterRecorder;
    _voiceRecording = false;
    unawaited(() async {
      try {
        if (await recorder.isRecording()) {
          await recorder.cancel();
        }
      } on Object {
        // Hot restart can race the native side; the dispose below still runs.
      }
      try {
        await recorder.dispose();
      } on Object {
        // Same race; swallow.
      }
      if (fallback != null) {
        try {
          await fallback.dispose();
        } on Object {
          // Fallback recorder is only used in tests; tolerate errors.
        }
      }
    }());
  }

  Future<bool> _voiceRecorderIsRecordingSafe() async {
    try {
      return await _voiceRecorder.isRecording();
    } on Object {
      return false;
    }
  }

  /// Releases the mic when the widget is removed or the app backgrounds mid-record.
  Future<void> _teardownVoiceRecording() async {
    _voiceMaxTimer?.cancel();
    _voiceMaxTimer = null;
    if (_voiceRecording || await _voiceRecorderIsRecordingSafe()) {
      await _discardVoiceCapture(deleteFile: true);
    }
  }

  AudioRecorder _resolveMeterRecorder() {
    final ChatVoiceRecorder r = _voiceRecorder;
    if (r is PackageChatVoiceRecorder) {
      return r.recorder;
    }
    return _fallbackMeterRecorder ??= AudioRecorder();
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: BorderDirectional(
          start: BorderSide(
            width: 3,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: context.l10n.eventChatVoiceDiscard,
            child: GestureDetector(
              onTap: _sendingVoiceReview ? null : _discardVoiceReview,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.xxs),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 22,
                  color: AppColors.textMuted,
                ),
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
                  style: AppTypography.eventsTextLinkEmphasis(
                    Theme.of(context).textTheme,
                  ).copyWith(color: AppColors.primary),
                ),
                Text(
                  _formatVoiceDuration(_voiceReviewLength),
                  style: AppTypography.eventsGridPropertyValue(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: context.l10n.eventChatVoiceSend,
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendingVoiceReview
                    ? null
                    : () => unawaited(_submitVoiceReview()),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _sendingVoiceReview
                      ? const AppLoadingIndicator(
                          size: AppLoadingIndicatorSize.sm,
                          color: AppColors.textOnDark,
                        )
                      : const Icon(
                          CupertinoIcons.arrow_up,
                          size: 20,
                          color: AppColors.textOnDark,
                        ),
                ),
              ),
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
    final Future<void> Function(XFile file, Duration recordedLength)? cb =
        widget.onSendVoice;
    if (f == null || cb == null || _sendingVoiceReview) {
      return;
    }
    setState(() => _sendingVoiceReview = true);
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
    final double pull = math.max(0, -_voicePanDx);
    final double cancelT = (pull / _kVoiceCancelEnterPx).clamp(0.0, 1.0);
    const Color danger = AppColors.error;
    const Color baseFill = AppColors.inputFill;
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
    final double borderWidth = _voiceCancelled
        ? 2
        : (cancelT > 0.06 ? 1 + cancelT * 0.6 : 0);

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: _voiceCancelled ? AppShadows.chatVoiceCancel(danger) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
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
                    _voiceCancelled
                        ? CupertinoIcons.xmark_circle_fill
                        : CupertinoIcons.mic_fill,
                    color: _voiceCancelled
                        ? danger
                        : Color.lerp(AppColors.primary, danger, cancelT),
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
                            recorder: _resolveMeterRecorder(),
                            active: _voiceRecording,
                            cancelled: _voiceCancelled,
                            reduceMotion: MediaQuery.disableAnimationsOf(
                              context,
                            ),
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
                                style:
                                    AppTypography.eventsCaptionStrong(
                                      Theme.of(context).textTheme,
                                      color: _voiceCancelled
                                          ? danger
                                          : AppColors.textPrimary,
                                    ).copyWith(
                                      fontSize: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.fontSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                              if (!_voiceCancelled)
                                Text(
                                  context.l10n.eventChatSlideToCancel,
                                  style: AppTypography.eventsChatSystemLine(
                                    Theme.of(context).textTheme,
                                  ).copyWith(height: 1.25),
                                )
                              else
                                Text(
                                  context.l10n.eventChatVoiceDiscard,
                                  style: AppTypography.eventsCaptionStrong(
                                    Theme.of(context).textTheme,
                                    color: danger.withValues(alpha: 0.88),
                                  ).copyWith(height: 1.25),
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
                  style:
                      AppTypography.eventsListCardTitle(
                        Theme.of(context).textTheme,
                      ).copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
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
                  borderRadius: AppRadii.chatMicro,
                  child: AppLinearProgress(
                    value: cancelT,
                    minHeight: 3,
                    backgroundColor: AppColors.divider.withValues(alpha: 0.4),
                    valueColor: danger.withValues(alpha: 0.45 + 0.45 * cancelT),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildVoiceTrailingAction(
    BuildContext context, {
    required bool canSend,
  }) {
    final bool showVoiceMic =
        !canSend &&
        _voiceReviewFile == null &&
        _voiceAttachAvailable &&
        widget.editingMessage == null;
    if (showVoiceMic) {
      return _buildVoiceMicButton(context);
    }
    if (_voiceReviewFile != null && widget.onSendVoice != null) {
      return const SizedBox(width: 44, height: 44);
    }
    return null;
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
                ? AppColors.error.withValues(alpha: 0.12)
                : AppColors.inputFill,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      LongPressGestureRecognizer
                    >(
                      () => LongPressGestureRecognizer(
                        duration: _kVoiceLongPressDuration,
                      ),
                      (LongPressGestureRecognizer instance) {
                        instance
                          ..onLongPressStart = _onVoiceLongPressStart
                          ..onLongPressMoveUpdate = _onVoiceLongPressMoveUpdate
                          ..onLongPressEnd = _onVoiceLongPressEndFromGesture
                          ..onLongPressCancel = _onVoiceLongPressGestureCancel;
                      },
                    ),
              },
              child: SizedBox.expand(
                child: Center(
                  child: Icon(
                    CupertinoIcons.mic_fill,
                    size: 22,
                    color: _voiceRecording
                        ? AppColors.error.withValues(alpha: 0.95)
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

  void _onVoiceLongPressEndFromGesture(LongPressEndDetails details) {
    unawaited(_onVoiceLongPressEnd());
  }

  void _onVoiceLongPressGestureCancel() {
    _voicePressHeld = false;
  }

  void _onVoiceLongPressStart(LongPressStartDetails details) {
    if (_mediaBlockedByNetwork()) {
      return;
    }
    if (!_voiceAttachAvailable || _composerBusy || _voiceReviewFile != null) {
      return;
    }
    _voicePressHeld = true;
    _voiceCancelled = false;
    _voicePanDx = 0;
    unawaited(_beginVoiceRecording());
  }

  Future<void> _showMicOpenSettingsDialog() async {
    if (!mounted) {
      return;
    }
    await showMicOpenSettingsDialog(context);
  }

  /// In-app rationale once, then OS prompt; on permanent denial offers Settings.
  Future<bool> _requestMicrophoneWithRationale() async {
    PermissionStatus st = await Permission.microphone.status;
    if (st.isGranted) {
      return true;
    }

    final prefs = ref.read(preferencesProvider);
    if (prefs.getBool(kEventChatMicRationaleCompletedKey) != true) {
      if (!mounted) {
        return false;
      }
      final bool? accepted = await showMicPermissionRationaleDialog(context);
      await prefs.setBool(kEventChatMicRationaleCompletedKey, true);
      if (accepted != true) {
        return false;
      }
    }

    st = await Permission.microphone.request();
    if (!st.isGranted) {
      if (mounted) {
        if (st.isPermanentlyDenied) {
          await _showMicOpenSettingsDialog();
        } else {
          AppSnack.show(
            context,
            message: context.l10n.eventChatMicPermissionDenied,
          );
        }
      }
      return false;
    }
    return true;
  }

  Future<void> _beginVoiceRecording() async {
    if (_voiceDisposed) {
      _voicePressHeld = false;
      return;
    }
    if (!_voiceAttachAvailable || _composerBusy || _voiceReviewFile != null) {
      _voicePressHeld = false;
      return;
    }
    final bool micOk = await _requestMicrophoneWithRationale();
    if (_voiceDisposed || !micOk) {
      _voicePressHeld = false;
      return;
    }
    if (!_voicePressHeld) {
      return;
    }
    final Directory dir = await getTemporaryDirectory();
    if (!_voicePressHeld) {
      return;
    }
    final String path =
        '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    _voicePath = path;
    try {
      await _voiceRecorder.start(
        config: RecordConfig(
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
    if (cancel != wasCancelled) {}
    setState(() {
      _voicePanDx = dx;
      _voiceCancelled = cancel;
    });
  }

  Future<void> _onVoiceLongPressEnd({bool forceSend = false}) async {
    _voiceMaxTimer?.cancel();
    _voiceMaxTimer = null;
    _voicePressHeld = false;

    final bool hardwareRecording = await _voiceRecorderIsRecordingSafe();
    if (!_voiceRecording && !hardwareRecording) {
      return;
    }

    final String? pathBeforeStop = _voicePath;
    final DateTime? recordStartedAt = _voiceRecordStartedAt;
    final bool send =
        pathBeforeStop != null &&
        _voiceAttachAvailable &&
        (forceSend || !_voiceCancelled);
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
      final String uploadPath = pathForUpload;
      if (widget.onSendVoice != null) {
        final Duration recorded = recordStartedAt != null
            ? DateTime.now().difference(recordStartedAt)
            : Duration.zero;
        setState(() {
          _voiceReviewFile = XFile(uploadPath, name: 'voice.m4a');
          _voiceReviewLength = recorded < Duration.zero
              ? Duration.zero
              : recorded;
        });
      } else {
        try {
          await widget.onSendImages!(<XFile>[
            XFile(uploadPath, name: 'voice.m4a'),
          ]);
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

  bool _mediaBlockedByNetwork();
}
