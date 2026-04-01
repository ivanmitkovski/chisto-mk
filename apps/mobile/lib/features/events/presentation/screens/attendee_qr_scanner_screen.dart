import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/check_in_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Custom painter that draws 4 L-shaped corner brackets with rounded inner corners.
class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter({
    required this.color,
    this.strokeWidth = 3,
    this.cornerRadius = 16,
    this.cornerLength = 40,
  });

  final Color color;
  final double strokeWidth;
  final double cornerRadius;
  final double cornerLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double r = cornerRadius.clamp(0, cornerLength / 2);
    final double len = cornerLength;

    final Path tl = Path()
      ..moveTo(len, 0)
      ..lineTo(r, 0)
      ..arcTo(Rect.fromLTWH(0, 0, r * 2, r * 2), -math.pi / 2, math.pi / 2, false)
      ..lineTo(0, len);
    canvas.drawPath(tl, paint);

    final Path tr = Path()
      ..moveTo(size.width - len, 0)
      ..lineTo(size.width - r, 0)
      ..arcTo(
        Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        0,
        math.pi / 2,
        false,
      )
      ..lineTo(size.width, len);
    canvas.drawPath(tr, paint);

    final Path bl = Path()
      ..moveTo(0, size.height - len)
      ..lineTo(0, size.height - r)
      ..arcTo(
        Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        math.pi,
        -math.pi / 2,
        false,
      )
      ..lineTo(len, size.height);
    canvas.drawPath(bl, paint);

    final Path br = Path()
      ..moveTo(size.width, size.height - len)
      ..lineTo(size.width, size.height - r)
      ..arcTo(
        Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        math.pi / 2,
        -math.pi / 2,
        false,
      )
      ..lineTo(size.width - len, size.height);
    canvas.drawPath(br, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      cornerRadius != oldDelegate.cornerRadius ||
      cornerLength != oldDelegate.cornerLength;
}

/// Custom painter that draws a checkmark path progressively (0..1).
class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 4,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(w * 0.2, h * 0.5)
      ..lineTo(w * 0.42, h * 0.72)
      ..lineTo(w * 0.82, h * 0.28);

    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final double totalLength = metrics.fold<double>(0, (double sum, ui.PathMetric m) => sum + m.length);
    final double drawLength = totalLength * progress.clamp(0, 1);

    double accumulated = 0;
    for (final ui.PathMetric metric in metrics) {
      final double len = metric.length;
      if (accumulated + len <= drawLength) {
        canvas.drawPath(metric.extractPath(0, len), _paint);
        accumulated += len;
      } else {
        final double t = (drawLength - accumulated) / len;
        canvas.drawPath(metric.extractPath(0, len * t), _paint);
        break;
      }
    }
  }

  Paint get _paint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

/// Screen for attendees to scan the organizer's QR code to check in.
/// Parses payload: chisto:evt:eventId:token
class AttendeeQrScannerScreen extends StatefulWidget {
  const AttendeeQrScannerScreen({
    super.key,
    required this.eventId,
    this.onCheckInSuccess,
  });

  final String eventId;
  final VoidCallback? onCheckInSuccess;

  @override
  State<AttendeeQrScannerScreen> createState() => _AttendeeQrScannerScreenState();
}

class _AttendeeQrScannerScreenState extends State<AttendeeQrScannerScreen>
    with SingleTickerProviderStateMixin {
  final CheckInRepository _checkInRepository = CheckInRepositoryRegistry.instance;
  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final TextEditingController _manualCodeController = TextEditingController();

  bool _scanned = false;
  bool _processing = false;
  bool _torchEnabled = false;
  bool _cameraReady = true;
  String? _feedback;
  DateTime? _checkedInAt;

  late AnimationController _scanLineController;

  EcoEvent? get _event => _eventsRepository.findById(widget.eventId);

  @override
  void initState() {
    super.initState();
    _eventsRepository.loadInitialIfNeeded();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _manualCodeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_scanned || _processing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _submitRawCode(raw);
  }

  void _submitRawCode(String rawCode) {
    if (_scanned || _processing) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    setState(() {
      _processing = true;
      _feedback = null;
    });

    final CheckInSubmissionResult result = _checkInRepository.submitScan(
      rawPayload: rawCode,
      expectedEventId: widget.eventId,
      attendeeId: CurrentUser.id,
      attendeeName: CurrentUser.displayName,
    );

    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      AppHaptics.success();
      setState(() {
        _scanned = true;
        _checkedInAt = result.checkedInAt;
        _processing = false;
      });
      widget.onCheckInSuccess?.call();
      return;
    }

    AppHaptics.warning();
    setState(() {
      _processing = false;
      _feedback = switch (result.status) {
        CheckInSubmissionStatus.invalidFormat => l10n.qrScannerErrorInvalidFormat,
        CheckInSubmissionStatus.wrongEvent => l10n.qrScannerErrorWrongEvent,
        CheckInSubmissionStatus.sessionClosed => l10n.qrScannerErrorSessionClosed,
        CheckInSubmissionStatus.sessionExpired => l10n.qrScannerErrorSessionExpired,
        CheckInSubmissionStatus.replayDetected => l10n.qrScannerErrorReplayDetected,
        CheckInSubmissionStatus.alreadyCheckedIn => l10n.qrScannerErrorAlreadyCheckedIn,
        CheckInSubmissionStatus.success => null,
      };
    });
  }

  Future<void> _toggleTorch() async {
    AppHaptics.tap();
    await _controller.toggleTorch();
    if (!mounted) return;
    setState(() => _torchEnabled = !_torchEnabled);
  }

  Future<void> _restartScanner() async {
    AppHaptics.tap();
    setState(() {
      _feedback = null;
      _cameraReady = true;
    });
    try {
      await _controller.stop();
      await _controller.start();
    } catch (_) {
      if (!mounted) {
        return;
      }
      final AppLocalizations l10n = context.l10n;
      setState(() {
        _cameraReady = false;
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
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    context.l10n.qrScannerManualEntryTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _manualCodeController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: context.l10n.qrScannerPasteOrganizerQrHint,
                            filled: true,
                            fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide: const BorderSide(color: AppColors.inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide: const BorderSide(color: AppColors.inputBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: () async {
                          final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            _manualCodeController.text = data!.text!;
                          }
                        },
                        icon: const Icon(CupertinoIcons.doc_on_clipboard),
                        tooltip: context.l10n.qrScannerPasteFromClipboardTooltip,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(context.l10n.commonCancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: context.l10n.qrScannerSubmitCode,
                          enabled: true,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
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
    _submitRawCode(raw);
  }

  void _handleDone() {
    AppHaptics.tap();
    Navigator.of(context).pop(_scanned);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;

    if (_scanned) {
      final AppLocalizations l10n = context.l10n;
      final String eventTitle = _event?.title ?? l10n.qrScannerGenericEventTitle;
      final String? checkedInTime = _checkedInAt == null
          ? null
          : '${_checkedInAt!.hour.toString().padLeft(2, '0')}:'
              '${_checkedInAt!.minute.toString().padLeft(2, '0')}';
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl + bottomSafe,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double progress, Widget? child) {
                      return CustomPaint(
                        painter: _CheckmarkPainter(
                          progress: progress,
                          color: AppColors.primaryDark,
                          strokeWidth: 4,
                        ),
                        size: const Size(80, 80),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.qrScannerCheckedInTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.qrScannerWelcomeTo(eventTitle),
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (checkedInTime != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.qrScannerCheckedInAt(checkedInTime),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const Spacer(),
                PrimaryButton(
                  label: l10n.qrScannerDone,
                  enabled: true,
                  onPressed: _handleDone,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          context.l10n.qrScannerAppBarTitle,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppColors.black.withValues(alpha: 0.54),
                    AppColors.transparent,
                    AppColors.transparent,
                    AppColors.black.withValues(alpha: 0.54),
                  ],
                  stops: const <double>[0.0, 0.2, 0.8, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _ScanFramePainter(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      strokeWidth: 3,
                      cornerRadius: 16,
                      cornerLength: 40,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (BuildContext context, Widget? child) {
                      final double t = _scanLineController.value;
                      final double top = 8 + t * (260 - 16);
                      return Positioned(
                        left: 8,
                        right: 8,
                        top: top,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
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
          Positioned(
            right: AppSpacing.lg,
            bottom: 100 + bottomSafe,
            child: Semantics(
              button: true,
              label: context.l10n.qrScannerToggleFlashlightSemantic,
              child: Material(
                color: AppColors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: InkWell(
                  onTap: _toggleTorch,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: Icon(
                      _torchEnabled ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 80 + bottomSafe,
            child: Column(
              children: <Widget>[
                Text(
                  _feedback ?? context.l10n.qrScannerPointCameraHint,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _feedback == null ? AppColors.textOnDarkMuted : Colors.orange.shade200,
                    fontWeight: _feedback == null ? FontWeight.w400 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    CupertinoButton(
                      onPressed: _openManualEntry,
                      padding: EdgeInsets.zero,
                      child: Text(
                        context.l10n.qrScannerEnterManually,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDarkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: _restartScanner,
                      padding: EdgeInsets.zero,
                      child: Text(
                        context.l10n.qrScannerRetryCamera,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDarkMuted,
                          fontWeight: FontWeight.w600,
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
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.54),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (_processing)
            Container(
              color: AppColors.black.withValues(alpha: 0.45),
              child: const Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
