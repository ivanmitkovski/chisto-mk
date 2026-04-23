import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/check_in_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/socket_check_in_stream.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_camera_error_layer.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_manual_entry_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_painters.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_pending_panel.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_scanner_chrome.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_success_panel.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

export 'attendee_qr_scanner_camera_error_layer.dart';

/// When set on [AttendeeQrScannerScreen], replaces [MobileScanner] for widget tests.
typedef AttendeeQrScannerTestSlotBuilder =
    Widget Function(
      BuildContext context,
      void Function(String rawPayload) simulateScan,
    );


/// Screen for attendees to scan the organizer's QR code to check in.
/// Parses payload: chisto:evt:eventId:token
class AttendeeQrScannerScreen extends StatefulWidget {
  const AttendeeQrScannerScreen({
    super.key,
    required this.eventId,
    this.onCheckInSuccess,
    @visibleForTesting this.scannerTestSlotBuilder,
  });

  final String eventId;
  final VoidCallback? onCheckInSuccess;

  /// Replaces [MobileScanner] so widget tests can simulate scans without a camera.
  final AttendeeQrScannerTestSlotBuilder? scannerTestSlotBuilder;

  @override
  State<AttendeeQrScannerScreen> createState() =>
      _AttendeeQrScannerScreenState();
}

class _AttendeeQrScannerScreenState extends State<AttendeeQrScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final CheckInRepository _checkInRepository =
      CheckInRepositoryRegistry.instance;
  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
  MobileScannerController? _controller;
  final TextEditingController _manualCodeController = TextEditingController();

  bool _scanned = false;
  bool _processing = false;
  bool _cameraReady = true;
  String? _feedback;
  CheckInSubmissionStatus? _lastFeedbackStatus;
  DateTime? _checkedInAt;
  int _checkInPointsAwarded = 0;
  DateTime? _scanCooldownUntil;

  // --- Pending confirmation state ---
  bool _pendingConfirmation = false;
  String? _pendingId;
  SocketCheckInStream? _checkInWs;
  StreamSubscription<CheckInStreamEvent>? _checkInWsSub;
  Timer? _pendingTimeoutTimer;
  Timer? _pendingPollTimer;

  late AnimationController _scanLineController;

  /// Avoids recomputing / pushing a new native scan window on every parent rebuild.
  double? _layoutW;
  double? _layoutH;
  double? _layoutBottomSafe;
  Rect? _cachedScanRect;

  static bool _isRecoverableScannerStatus(CheckInSubmissionStatus status) {
    return status == CheckInSubmissionStatus.sessionExpired ||
        status == CheckInSubmissionStatus.replayDetected ||
        status == CheckInSubmissionStatus.rateLimited ||
        status == CheckInSubmissionStatus.sessionClosed ||
        status == CheckInSubmissionStatus.requiresJoin ||
        status == CheckInSubmissionStatus.checkInUnavailable ||
        status == CheckInSubmissionStatus.alreadyCheckedIn;
  }

  EcoEvent? get _event => _eventsRepository.findById(widget.eventId);

  static const double _scanFrameCornerRadius = 16;
  static const double _topInstructionReserve = 96;
  static const double _bottomActionsReserve = 132;

  /// Scan square in body coordinates; matches [MobileScanner.scanWindow] when not on web.
  Rect _scanRectInBody(double width, double height, double bottomSafe) {
    final double maxSide = math.min(280, width - AppSpacing.lg * 2);
    final double side = maxSide.clamp(208, 280);
    final double bottomBlock = bottomSafe + _bottomActionsReserve;
    final double y =
        _topInstructionReserve +
        math.max(0, (height - _topInstructionReserve - bottomBlock - side) / 2);
    final double x = (width - side) / 2;
    return Rect.fromLTWH(x, y, side, side);
  }

  Rect _stableScanRect(double width, double height, double bottomSafe) {
    if (_layoutW == width &&
        _layoutH == height &&
        _layoutBottomSafe == bottomSafe &&
        _cachedScanRect != null) {
      return _cachedScanRect!;
    }
    _layoutW = width;
    _layoutH = height;
    _layoutBottomSafe = bottomSafe;
    _cachedScanRect = _scanRectInBody(width, height, bottomSafe);
    return _cachedScanRect!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.scannerTestSlotBuilder == null) {
      _controller = MobileScannerController(
        lensType: CameraLensType.normal,
        formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.unrestricted,
        facing: CameraFacing.back,
        autoZoom: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
        cameraResolution:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? const Size(1280, 720)
            : null,
      );
    }
    _eventsRepository.loadInitialIfNeeded();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeScanLineAnimationIfNeeded();
    });
  }

  /// Stops the looping scan line when reduce motion / test [MediaQuery.disableAnimations] is on.
  void _resumeScanLineAnimationIfNeeded() {
    if (!mounted || _scanned || _processing) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _scanLineController.stop();
      _scanLineController.value = 0.5;
      return;
    }
    _scanLineController.repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLineController.dispose();
    _manualCodeController.dispose();
    _controller?.dispose();
    _pendingTimeoutTimer?.cancel();
    _pendingPollTimer?.cancel();
    _checkInWsSub?.cancel();
    _checkInWs?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // External controller: MobileScanner does not register lifecycle — release camera when
    // backgrounded and restart on resume to avoid frozen or black preview.
    if (!mounted || _scanned) {
      return;
    }
    switch (state) {
      case AppLifecycleState.inactive:
        _scanLineController.stop();
        final MobileScannerController? c = _controller;
        if (c != null) {
          unawaited(c.stop());
        }
        break;
      case AppLifecycleState.resumed:
        unawaited(_resumeCameraAfterLifecycle());
        if (_pendingConfirmation && _pendingId != null) {
          unawaited(_pollPendingStatus());
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        break;
    }
  }

  Future<void> _resumeCameraAfterLifecycle() async {
    if (!mounted || _scanned) {
      return;
    }
    final MobileScannerController? c = _controller;
    if (c == null) {
      return;
    }
    try {
      await c.start();
      if (mounted) {
        setState(() => _cameraReady = true);
        if (!_scanned) {
          _resumeScanLineAnimationIfNeeded();
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraReady = false;
        _feedback = context.l10n.qrScannerCameraUnavailableFeedback;
      });
    }
  }

  /// Keeps [EcoEvent.isCheckedIn] in sync so event detail CTAs refresh after check-in
  /// (especially after organizer approves a pending request — no redeem HTTP body then).
  void _markAttendeeCheckedInOnEventsStore(DateTime? checkedInAt) {
    _eventsRepository.setAttendeeCheckInStatus(
      eventId: widget.eventId,
      status: AttendeeCheckInStatus.checkedIn,
      checkedInAt: checkedInAt ?? DateTime.now(),
    );
    unawaited(_eventsRepository.prefetchEvent(widget.eventId, force: true));
  }

  /// Releases the camera and scan animation once check-in is done or while awaiting organizer.
  Future<void> _suspendScanningHardware() async {
    if (!mounted) {
      return;
    }
    _scanLineController.stop();
    final MobileScannerController? c = _controller;
    if (c == null) {
      return;
    }
    try {
      await c.stop();
    } on Object {
      // Camera may already be stopped; ignore.
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_scanned || _processing || _pendingConfirmation) return;
    final DateTime now = DateTime.now();
    if (_scanCooldownUntil != null && now.isBefore(_scanCooldownUntil!)) {
      return;
    }
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    unawaited(_submitRawCode(raw));
  }

  static const Duration _kScanFailureCooldown = Duration(milliseconds: 1500);

  Future<void> _submitRawCode(String rawCode) async {
    if (_scanned || _processing || _pendingConfirmation) {
      return;
    }
    // Set synchronously so rapid [onDetect] bursts cannot enqueue overlapping submits.
    _processing = true;
    _scanLineController.stop();
    final AppLocalizations l10n = context.l10n;
    setState(() {
      _feedback = null;
    });

    final CheckInSubmissionResult result = await _checkInRepository.submitScan(
      rawPayload: rawCode,
      expectedEventId: widget.eventId,
      attendeeId: CurrentUser.id,
      attendeeName: CurrentUser.displayName,
    );

    if (!mounted) {
      _processing = false;
      return;
    }
    if (result.isSuccess) {
      AppHaptics.success();
      await _suspendScanningHardware();
      if (!mounted) {
        return;
      }
      setState(() {
        _scanned = true;
        _checkedInAt = result.checkedInAt;
        _checkInPointsAwarded = result.pointsAwarded;
        _processing = false;
      });
      _markAttendeeCheckedInOnEventsStore(result.checkedInAt);
      widget.onCheckInSuccess?.call();
      return;
    }

    if (result.isPendingConfirmation) {
      AppHaptics.tap();
      await _suspendScanningHardware();
      if (!mounted) {
        return;
      }
      setState(() {
        _processing = false;
        _pendingConfirmation = true;
        _pendingId = result.pendingId;
        _feedback = null;
      });
      _startPendingConfirmationFlow(result);
      return;
    }

    // Offline: treat as optimistic success (will sync when back online).
    if (result.status == CheckInSubmissionStatus.queuedOffline) {
      AppHaptics.success();
      await _suspendScanningHardware();
      if (!mounted) {
        return;
      }
      setState(() {
        _scanned = true;
        _checkedInAt = null;
        _processing = false;
        _feedback = l10n.eventsOfflineSyncQueued;
      });
      _markAttendeeCheckedInOnEventsStore(DateTime.now());
      return;
    }

    if (result.status == CheckInSubmissionStatus.alreadyCheckedIn) {
      AppHaptics.success();
      await _suspendScanningHardware();
      if (!mounted) {
        return;
      }
      setState(() {
        _scanned = true;
        _checkedInAt = result.checkedInAt ?? DateTime.now();
        _checkInPointsAwarded = result.pointsAwarded;
        _processing = false;
        _feedback = null;
      });
      _markAttendeeCheckedInOnEventsStore(result.checkedInAt);
      widget.onCheckInSuccess?.call();
      return;
    }

    AppHaptics.warning();
    final CheckInSubmissionStatus st = result.status;
    _scanCooldownUntil = DateTime.now().add(_kScanFailureCooldown);
    setState(() {
      _processing = false;
      _lastFeedbackStatus = st;
      _feedback = switch (st) {
        CheckInSubmissionStatus.invalidFormat =>
          l10n.qrScannerErrorInvalidFormat,
        CheckInSubmissionStatus.invalidQr => l10n.qrScannerErrorInvalidQr,
        CheckInSubmissionStatus.wrongEvent => l10n.qrScannerErrorWrongEvent,
        CheckInSubmissionStatus.sessionClosed =>
          l10n.qrScannerErrorSessionClosed,
        CheckInSubmissionStatus.sessionExpired =>
          l10n.qrScannerErrorSessionExpired,
        CheckInSubmissionStatus.replayDetected =>
          l10n.qrScannerErrorReplayDetected,
        CheckInSubmissionStatus.alreadyCheckedIn =>
          l10n.qrScannerErrorAlreadyCheckedIn,
        CheckInSubmissionStatus.requiresJoin => l10n.qrScannerErrorRequiresJoin,
        CheckInSubmissionStatus.checkInUnavailable =>
          l10n.qrScannerErrorCheckInUnavailable,
        CheckInSubmissionStatus.rateLimited => l10n.qrScannerErrorRateLimited,
        CheckInSubmissionStatus.success => null,
        CheckInSubmissionStatus.queuedOffline => l10n.eventsOfflineSyncQueued,
        CheckInSubmissionStatus.pendingConfirmation => null,
      };
    });
    if (!_scanned && mounted) {
      _resumeScanLineAnimationIfNeeded();
    }
  }

  // --- Pending confirmation flow (volunteer side) ---

  void _startPendingConfirmationFlow(CheckInSubmissionResult result) {
    final ServiceLocator sl = ServiceLocator.instance;
    _checkInWs = SocketCheckInStream(
      baseUrl: sl.config.apiBaseUrl,
      authState: sl.authState,
    );
    _checkInWsSub = _checkInWs!.stream.listen(_onPendingWsEvent);
    _checkInWs!.connect(widget.eventId);

    // Client-side timeout based on server expiresAt (fallback 60s).
    final int timeoutMs = result.pendingExpiresAt != null
        ? result.pendingExpiresAt!
              .difference(DateTime.now())
              .inMilliseconds
              .clamp(5000, 120000)
        : 60000;
    _pendingTimeoutTimer = Timer(Duration(milliseconds: timeoutMs), () {
      if (!mounted || !_pendingConfirmation) return;
      _onPendingExpired();
    });

    // Fallback poll while waiting on organizer (tightens when WS is down).
    _restartPendingPollTimer(fast: false);
  }

  void _restartPendingPollTimer({required bool fast}) {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = Timer.periodic(Duration(seconds: fast ? 1 : 3), (_) {
      if (!mounted || !_pendingConfirmation || _pendingId == null) return;
      unawaited(_pollPendingStatus());
    });
  }

  void _onPendingWsEvent(CheckInStreamEvent event) {
    if (!mounted || !_pendingConfirmation) return;
    if (event is CheckInConnectionChanged) {
      if (event.status != CheckInWsConnectionStatus.connected) {
        unawaited(_pollPendingStatus());
        _restartPendingPollTimer(fast: true);
      } else {
        _restartPendingPollTimer(fast: false);
      }
      return;
    }
    if (event is CheckInConfirmedEvent && event.pendingId == _pendingId) {
      _onPendingConfirmed(
        checkedInAt: DateTime.tryParse(event.checkedInAt),
        pointsAwarded: event.pointsAwarded,
      );
    } else if (event is CheckInRejectedEvent && event.pendingId == _pendingId) {
      _onPendingRejected();
    }
  }

  Future<void> _pollPendingStatus() async {
    if (_pendingId == null) return;
    final String? status = await _checkInRepository.pollPendingStatus(
      eventId: widget.eventId,
      pendingId: _pendingId!,
    );
    if (!mounted || !_pendingConfirmation) return;
    if (status == 'expired') {
      _onPendingExpired();
    }
  }

  void _onPendingConfirmed({DateTime? checkedInAt, int pointsAwarded = 0}) {
    _cleanupPendingState();
    AppHaptics.success();
    _markAttendeeCheckedInOnEventsStore(checkedInAt);
    setState(() {
      _pendingConfirmation = false;
      _scanned = true;
      _checkedInAt = checkedInAt;
      _checkInPointsAwarded = pointsAwarded;
    });
    widget.onCheckInSuccess?.call();
  }

  void _onPendingRejected() {
    _cleanupPendingState();
    AppHaptics.warning();
    setState(() {
      _pendingConfirmation = false;
      _feedback = context.l10n.eventsVolunteerRejected;
    });
    unawaited(_resumeCameraAfterLifecycle());
    _resumeScanLineAnimationIfNeeded();
  }

  void _onPendingExpired() {
    _cleanupPendingState();
    AppHaptics.warning();
    setState(() {
      _pendingConfirmation = false;
      _feedback = context.l10n.eventsVolunteerExpired;
    });
    unawaited(_resumeCameraAfterLifecycle());
    _resumeScanLineAnimationIfNeeded();
  }

  void _cleanupPendingState() {
    _pendingTimeoutTimer?.cancel();
    _pendingTimeoutTimer = null;
    _pendingPollTimer?.cancel();
    _pendingPollTimer = null;
    _checkInWsSub?.cancel();
    _checkInWsSub = null;
    _checkInWs?.dispose();
    _checkInWs = null;
    _pendingId = null;
  }

  Future<void> _restartScanner() async {
    AppHaptics.tap();
    setState(() {
      _feedback = null;
      _lastFeedbackStatus = null;
      _scanCooldownUntil = null;
      _cameraReady = true;
    });
    final MobileScannerController? c = _controller;
    if (c == null) {
      if (mounted && !_scanned) {
        _resumeScanLineAnimationIfNeeded();
      }
      return;
    }
    try {
      await c.stop();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await c.start();
      if (mounted && !_scanned) {
        _resumeScanLineAnimationIfNeeded();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      final AppLocalizations l10n = context.l10n;
      setState(() {
        _cameraReady = false;
        _lastFeedbackStatus = null;
        _feedback = l10n.qrScannerCameraUnavailableFeedback;
      });
    }
  }

  Future<void> _openManualEntry() async {
    AppHaptics.tap();
    _manualCodeController.clear();
    final bool? submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext sheetContext) {
        // Bottom-sheet routes often inherit a [MediaQuery] where padding and
        // viewPadding are cleared; read the real display insets from the view.
        final MediaQueryData viewMq = MediaQueryData.fromView(
          View.of(sheetContext),
        );
        final EdgeInsets viewPad = viewMq.viewPadding;
        // Remove bottom viewInsets so the keyboard overlays the sheet rather
        // than shrinking it and pushing the pinned footer up.
        return MediaQuery.removeViewInsets(
          context: sheetContext,
          removeBottom: true,
          child: SizedBox(
            width: viewMq.size.width,
            height: viewMq.size.height,
            child: SafeArea(
              top: true,
              bottom: false,
              left: false,
              right: false,
              // Force at least the physical view padding (notch / status bar).
              minimum: EdgeInsets.only(
                top: viewPad.top,
                left: viewPad.left,
                right: viewPad.right,
              ),
              child: AttendeeManualCodeEntrySheet(
                controller: _manualCodeController,
              ),
            ),
          ),
        );
      },
    );

    if (submit != true) {
      return;
    }
    if (!mounted) {
      return;
    }
    final String raw = _manualCodeController.text.trim();
    if (raw.isEmpty) {
      setState(() => _feedback = context.l10n.qrScannerEnterCodeFirst);
      return;
    }
    unawaited(_submitRawCode(raw));
  }

  Widget _scannerErrorLayer(
    BuildContext context,
    MobileScannerException error,
  ) {
    return attendeeQrScannerCameraErrorLayer(
      context,
      errorCode: error.errorCode,
      onRetryCamera: _restartScanner,
      onEnterManually: _openManualEntry,
    );
  }

  void _handleDone() {
    AppHaptics.tap();
    Navigator.of(context).pop(_scanned);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;

    if (_pendingConfirmation) {
      final AppLocalizations l10n = context.l10n;
      return AttendeeQrScannerPendingPanel(
        eventTitle: _event?.title ?? l10n.qrScannerGenericEventTitle,
        bottomSafe: bottomSafe,
        onCancel: () {
          _cleanupPendingState();
          setState(() {
            _pendingConfirmation = false;
            _feedback = null;
          });
          unawaited(_resumeCameraAfterLifecycle());
          _resumeScanLineAnimationIfNeeded();
        },
      );
    }

    if (_scanned) {
      final AppLocalizations l10n = context.l10n;
      final String eventTitle =
          _event?.title ?? l10n.qrScannerGenericEventTitle;
      final String? checkedInTime = _checkedInAt == null
          ? null
          : formatCheckInTime(_checkedInAt!);
      return AttendeeQrScannerSuccessScaffold(
        eventTitle: eventTitle,
        checkedInTime: checkedInTime,
        pointsAwarded: _checkInPointsAwarded,
        bottomSafe: bottomSafe,
        onDone: _handleDone,
      );
    }

    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Center(
              child: AppBackButton(
                backgroundColor: AppColors.white.withValues(alpha: 0.14),
                iconColor: AppColors.white,
              ),
            ),
          ),
          title: Text(
            context.l10n.qrScannerAppBarTitle,
            style: AppTypography.eventsHeroCardTitle(textTheme).copyWith(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final Rect scanRect = _stableScanRect(w, h, bottomSafe);
            final double side = scanRect.width;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (widget.scannerTestSlotBuilder != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.black,
                      child: widget.scannerTestSlotBuilder!(
                        context,
                        (String raw) => unawaited(_submitRawCode(raw)),
                      ),
                    ),
                  )
                else
                  Semantics(
                    label: context.l10n.qrScannerPointCameraHint,
                    child: MobileScanner(
                      controller: _controller!,
                      onDetect: _handleBarcode,
                      placeholderBuilder: attendeeQrScannerLoadingLayer,
                      errorBuilder: _scannerErrorLayer,
                      tapToFocus: false,
                      scanWindow: kIsWeb ? null : scanRect,
                      scanWindowUpdateThreshold: 48,
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: AttendeeQrDimOutsideScanPainter(
                        scanRect: scanRect,
                        overlayColor: AppColors.black.withValues(alpha: 0.5),
                        holeRadius: _scanFrameCornerRadius,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: scanRect.left,
                  top: scanRect.top,
                  width: scanRect.width,
                  height: scanRect.height,
                  child: Semantics(
                    container: true,
                    label: context.l10n.qrScannerPointCameraHint,
                    child: IgnorePointer(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          CustomPaint(
                            size: Size.square(side),
                            painter: AttendeeQrSquareScanFramePainter(
                              color: AppColors.primary.withValues(alpha: 0.95),
                              strokeWidth: 3,
                              cornerRadius: _scanFrameCornerRadius,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _scanLineController,
                            builder: (BuildContext context, Widget? child) {
                              final double t = _scanLineController.value;
                              const double inset = 10;
                              final double travel = math.max(
                                0,
                                side - 2 * inset - 4,
                              );
                              final double top = inset + t * travel;
                              return Positioned(
                                left: inset,
                                right: inset,
                                top: top,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.85,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  child: IgnorePointer(
                    child: attendeeQrScannerGlassChip(
                      context,
                      icon: CupertinoIcons.qrcode_viewfinder,
                      text: context.l10n.qrScannerPointCameraHint,
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: bottomSafe + AppSpacing.md,
                  child: SafeArea(
                    top: false,
                    child: attendeeQrScannerGlassBottomPanel(
                      context,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_feedback != null) ...<Widget>[
                            Text(
                              _feedback!,
                              style: AppTypography.eventsChatMessageBody(textTheme).copyWith(
                                color:
                                    (_lastFeedbackStatus == null ||
                                        _isRecoverableScannerStatus(
                                          _lastFeedbackStatus!,
                                        ))
                                    ? AppColors.accentWarning
                                    : AppColors.accentDanger,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: <Widget>[
                              Semantics(
                                button: true,
                                label: context.l10n.qrScannerEnterManually,
                                child: CupertinoButton(
                                  onPressed: _openManualEntry,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  minimumSize: Size.zero,
                                  child: Text(
                                    context.l10n.qrScannerEnterManually,
                                    style: AppTypography.eventsCaptionStrong(
                                      textTheme,
                                      color: AppColors.textOnDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: context.l10n.qrScannerRetryCamera,
                                child: CupertinoButton(
                                  onPressed: _restartScanner,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  minimumSize: Size.zero,
                                  child: Text(
                                    context.l10n.qrScannerRetryCamera,
                                    style: AppTypography.eventsCaptionStrong(
                                      textTheme,
                                      color: AppColors.textOnDarkMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _cameraReady
                                ? context.l10n.qrScannerHintFreshQr
                                : context.l10n.qrScannerHintCameraBlocked,
                            style: AppTypography.eventsHeroCardMeta(textTheme).copyWith(
                              color: AppColors.white.withValues(alpha: 0.55),
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_processing)
                  Semantics(
                    label: context.l10n.qrScannerCheckingIn,
                    child: ColoredBox(
                      color: AppColors.black.withValues(alpha: 0.52),
                      child: Center(child: attendeeQrScannerProcessingHud(context)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
