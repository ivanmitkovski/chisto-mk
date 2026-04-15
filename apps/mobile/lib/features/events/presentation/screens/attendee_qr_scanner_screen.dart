import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
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

/// When set on [AttendeeQrScannerScreen], replaces [MobileScanner] for widget tests.
typedef AttendeeQrScannerTestSlotBuilder = Widget Function(
  BuildContext context,
  void Function(String rawPayload) simulateScan,
);

String _attendeeQrScannerMobileScannerErrorBody(
  MobileScannerErrorCode code,
  AppLocalizations l10n,
) {
  switch (code) {
    case MobileScannerErrorCode.permissionDenied:
      return l10n.qrScannerHintCameraBlocked;
    case MobileScannerErrorCode.unsupported:
      return l10n.qrScannerCameraUnavailableFeedback;
    default:
      return l10n.qrScannerCameraUnavailableFeedback;
  }
}

/// Permission-denied and other camera errors from [mobile_scanner] — widget-tested in isolation.
@visibleForTesting
Widget attendeeQrScannerCameraErrorLayerForTesting(
  BuildContext context, {
  required MobileScannerErrorCode errorCode,
  required VoidCallback onRetryCamera,
  required VoidCallback onEnterManually,
}) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final AppLocalizations l10n = context.l10n;
  final String detail = _attendeeQrScannerMobileScannerErrorBody(errorCode, l10n);
  return ColoredBox(
    color: AppColors.black,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Semantics(
              container: true,
              label: '${l10n.qrScannerCameraErrorTitle}. $detail',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: AppColors.accentWarning,
                    size: 44,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.qrScannerCameraErrorTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textOnDarkMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                Semantics(
                  button: true,
                  label: l10n.qrScannerRetryCamera,
                  child: CupertinoButton(
                    onPressed: onRetryCamera,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      l10n.qrScannerRetryCamera,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.qrScannerEnterManually,
                  child: CupertinoButton(
                    onPressed: onEnterManually,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      l10n.qrScannerEnterManually,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Darkens the preview outside [scanRect] so the target area reads as one square.
class _DimOutsideScanPainter extends CustomPainter {
  _DimOutsideScanPainter({
    required this.scanRect,
    required this.overlayColor,
    this.holeRadius = 16,
  });

  final Rect scanRect;
  final Color overlayColor;
  final double holeRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Path outer = Path()..addRect(Offset.zero & size);
    final Path hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, Radius.circular(holeRadius)),
      );
    final Path mask = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(mask, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant _DimOutsideScanPainter oldDelegate) =>
      scanRect != oldDelegate.scanRect ||
      overlayColor != oldDelegate.overlayColor ||
      holeRadius != oldDelegate.holeRadius;
}

/// Solid rounded-rect outline + decorative QR-like dot field **inside** the square.
///
/// Finder patterns and timing strips read clearly; data area uses a light dither.
/// Inner radial wash + tiered opacity keeps the camera preview readable.
class _SquareScanFramePainter extends CustomPainter {
  _SquareScanFramePainter({
    required this.color,
    this.strokeWidth = 3,
    this.cornerRadius = 16,
  });

  final Color color;
  final double strokeWidth;
  final double cornerRadius;

  static const double _innerInset = 15;
  /// Standard QR finder pattern (7×7, `true` = dark module).
  static const List<List<bool>> _finder7 = <List<bool>>[
    <bool>[true, true, true, true, true, true, true],
    <bool>[true, false, false, false, false, false, true],
    <bool>[true, false, true, true, true, false, true],
    <bool>[true, false, true, true, true, false, true],
    <bool>[true, false, true, true, true, false, true],
    <bool>[true, false, false, false, false, false, true],
    <bool>[true, true, true, true, true, true, true],
  ];

  /// Returns whether the cell is “inked” and which visual tier to use.
  static _QrDotTier? _moduleTier(int row, int col, int rows, int cols) {
    if (cols >= 7 && rows >= 7) {
      if (row < 7 && col < 7) {
        return _finder7[row][col] ? _QrDotTier.finder : null;
      }
      if (row < 7 && col >= cols - 7) {
        return _finder7[row][col - (cols - 7)] ? _QrDotTier.finder : null;
      }
      if (row >= rows - 7 && col < 7) {
        return _finder7[row - (rows - 7)][col] ? _QrDotTier.finder : null;
      }
    }
    if (cols >= 14 && rows >= 14) {
      if (row == 6 && col >= 7 && col < cols - 7) {
        return (col - 7).isEven ? _QrDotTier.timing : null;
      }
      if (col == 6 && row >= 7 && row < rows - 7) {
        return (row - 7).isEven ? _QrDotTier.timing : null;
      }
    }
    if (((row * 17 + col * 31) & 7) < 3) {
      return _QrDotTier.data;
    }
    return null;
  }

  static void _paintInnerCornerAccents(
    Canvas canvas,
    RRect inner,
    Color accent,
  ) {
    final double inset = math.max(5, inner.width * 0.04);
    final double d = 2.2;
    final Paint p = Paint()
      ..isAntiAlias = true
      ..color = accent;
    void cornerDots(double lx, double ty) {
      canvas.drawCircle(Offset(lx, ty), d, p);
      canvas.drawCircle(Offset(lx + 5, ty), d * 0.85, p);
      canvas.drawCircle(Offset(lx, ty + 5), d * 0.85, p);
    }

    cornerDots(inner.left + inset, inner.top + inset);
    cornerDots(inner.right - inset - 5, inner.top + inset);
    cornerDots(inner.left + inset, inner.bottom - inset - 5);
    cornerDots(inner.right - inset - 5, inner.bottom - inset - 5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final RRect r = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius.clamp(0, rect.shortestSide / 2)),
    );

    final RRect inner = r.deflate(_innerInset);
    if (inner.width > 32 && inner.height > 32) {
      final double shortest = math.min(inner.width, inner.height);
      const int targetModules = 23;
      final double module = shortest / targetModules;
      final int cols = math.max(7, (inner.width / module).floor());
      final int rows = math.max(7, (inner.height / module).floor());
      final double offsetX = inner.left + (inner.width - cols * module) / 2;
      final double offsetY = inner.top + (inner.height - rows * module) / 2;
      final double baseDotR = (module * 0.36).clamp(1.0, 2.35);

      canvas.save();
      canvas.clipRRect(inner);

      final Paint wash = Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          inner.center,
          shortest * 0.62,
          <Color>[
            color.withValues(alpha: 0.11),
            color.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          <double>[0.0, 0.45, 1.0],
        );
      canvas.drawRRect(inner, wash);

      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          final _QrDotTier? tier = _moduleTier(row, col, rows, cols);
          if (tier == null) {
            continue;
          }
          final Offset c = Offset(
            offsetX + (col + 0.5) * module,
            offsetY + (row + 0.5) * module,
          );
          if (!inner.contains(c)) {
            continue;
          }

          final double radiusMul;
          final double alpha;
          final Color dotColor;
          switch (tier) {
            case _QrDotTier.finder:
              radiusMul = 1.28;
              alpha = 0.58;
              dotColor = Color.lerp(color, AppColors.white, 0.42)!;
            case _QrDotTier.timing:
              radiusMul = 1.08;
              alpha = 0.4;
              dotColor = Color.lerp(color, AppColors.white, 0.22)!;
            case _QrDotTier.data:
              radiusMul = 1.0;
              alpha = 0.26;
              dotColor = color;
          }

          final double r = baseDotR * radiusMul;
          if (tier == _QrDotTier.finder) {
            canvas.drawCircle(
              c,
              r * 1.5,
              Paint()
                ..isAntiAlias = true
                ..color = color.withValues(alpha: 0.09),
            );
          }
          final Paint dotPaint = Paint()
            ..isAntiAlias = true
            ..color = dotColor.withValues(alpha: alpha);
          canvas.drawCircle(c, r, dotPaint);
        }
      }

      _paintInnerCornerAccents(
        canvas,
        inner,
        AppColors.white.withValues(alpha: 0.22),
      );
      canvas.restore();
    }

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawRRect(r, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SquareScanFramePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      cornerRadius != oldDelegate.cornerRadius;
}

enum _QrDotTier { finder, timing, data }

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

class _ManualEntrySheetHandle extends StatelessWidget {
  const _ManualEntrySheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Center(
        child: Container(
          width: AppSpacing.sheetHandle,
          height: AppSpacing.sheetHandleHeight,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius:
                BorderRadius.circular(AppSpacing.sheetHandleHeight / 2),
          ),
        ),
      ),
    );
  }
}

/// Manual QR code entry sheet for attendees.
/// The modal host uses [MediaQueryData.fromView] + [SafeArea.minimum] so insets
/// stay correct when the bottom-sheet route’s inherited [MediaQuery] zeros out
/// [padding]/[viewPadding] (common with edge-to-edge). Cancel + Submit stay
/// pinned; the keyboard overlays the sheet (host strips bottom viewInsets).
class _AttendeeManualCodeEntrySheet extends StatefulWidget {
  const _AttendeeManualCodeEntrySheet({required this.controller});

  final TextEditingController controller;

  @override
  State<_AttendeeManualCodeEntrySheet> createState() =>
      _AttendeeManualCodeEntrySheetState();
}

class _AttendeeManualCodeEntrySheetState
    extends State<_AttendeeManualCodeEntrySheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  bool get _canSubmit => widget.controller.text.trim().isNotEmpty;

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) {
      return;
    }
    AppHaptics.tap();
    widget.controller.text = data!.text!;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SizedBox.expand(
        child: Material(
          color: AppColors.panelBackground,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── scrollable body ──────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _ManualEntrySheetHandle(),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.qrScannerManualEntryTitle,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.qrScannerManualEntrySubtitle,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.commonClose,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CupertinoTextField(
                        controller: widget.controller,
                        autofocus: true,
                        minLines: 4,
                        maxLines: 8,
                        placeholder: l10n.qrScannerPasteOrganizerQrHint,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                        placeholderStyle: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: Icon(
                          CupertinoIcons.doc_on_clipboard,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                        label: Text(
                          l10n.qrScannerPasteButton,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: AppColors.inputBorder),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                            horizontal: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── pinned footer ─────────────────────────────────────────────
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.panelBackground,
                  border: Border(
                    top: BorderSide(color: AppColors.divider, width: 0.5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md + bottomSafe,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                            ),
                            child: Text(
                              l10n.commonCancel,
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: l10n.qrScannerSubmitCode,
                          enabled: _canSubmit,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  State<AttendeeQrScannerScreen> createState() => _AttendeeQrScannerScreenState();
}

class _AttendeeQrScannerScreenState extends State<AttendeeQrScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final CheckInRepository _checkInRepository = CheckInRepositoryRegistry.instance;
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
    final double y = _topInstructionReserve +
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
        cameraResolution: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
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

  void _handleBarcode(BarcodeCapture capture) {
    if (_scanned || _processing) return;
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
    if (_scanned || _processing) {
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
      setState(() {
        _scanned = true;
        _checkedInAt = result.checkedInAt;
        _checkInPointsAwarded = result.pointsAwarded;
        _processing = false;
      });
      widget.onCheckInSuccess?.call();
      return;
    }

    // Offline: treat as optimistic success (will sync when back online).
    if (result.status == CheckInSubmissionStatus.queuedOffline) {
      AppHaptics.success();
      setState(() {
        _scanned = true;
        _checkedInAt = null;
        _processing = false;
        _feedback = l10n.eventsOfflineSyncQueued;
      });
      return;
    }

    AppHaptics.warning();
    final CheckInSubmissionStatus st = result.status;
    // Unrestricted detection keeps firing on the same bad QR — throttle scans + haptics.
    _scanCooldownUntil = DateTime.now().add(_kScanFailureCooldown);
    setState(() {
      _processing = false;
      _lastFeedbackStatus = st;
      _feedback = switch (st) {
        CheckInSubmissionStatus.invalidFormat => l10n.qrScannerErrorInvalidFormat,
        CheckInSubmissionStatus.invalidQr => l10n.qrScannerErrorInvalidQr,
        CheckInSubmissionStatus.wrongEvent => l10n.qrScannerErrorWrongEvent,
        CheckInSubmissionStatus.sessionClosed => l10n.qrScannerErrorSessionClosed,
        CheckInSubmissionStatus.sessionExpired => l10n.qrScannerErrorSessionExpired,
        CheckInSubmissionStatus.replayDetected => l10n.qrScannerErrorReplayDetected,
        CheckInSubmissionStatus.alreadyCheckedIn => l10n.qrScannerErrorAlreadyCheckedIn,
        CheckInSubmissionStatus.requiresJoin => l10n.qrScannerErrorRequiresJoin,
        CheckInSubmissionStatus.checkInUnavailable =>
          l10n.qrScannerErrorCheckInUnavailable,
        CheckInSubmissionStatus.rateLimited => l10n.qrScannerErrorRateLimited,
        CheckInSubmissionStatus.success => null,
        CheckInSubmissionStatus.queuedOffline => l10n.eventsOfflineSyncQueued,
      };
    });
    if (!_scanned && mounted) {
      _resumeScanLineAnimationIfNeeded();
    }
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
        final MediaQueryData viewMq =
            MediaQueryData.fromView(View.of(sheetContext));
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
              child: _AttendeeManualCodeEntrySheet(
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

  Widget _scannerLoadingLayer(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    return ColoredBox(
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CupertinoActivityIndicator(color: AppColors.white),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                l10n.qrScannerCameraStarting,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnDarkMuted,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scannerErrorLayer(BuildContext context, MobileScannerException error) {
    return attendeeQrScannerCameraErrorLayerForTesting(
      context,
      errorCode: error.errorCode,
      onRetryCamera: _restartScanner,
      onEnterManually: _openManualEntry,
    );
  }

  Widget _glassScannerChip(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnDark,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (reduceMotion) {
      return inner;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: inner,
      ),
    );
  }

  Widget _glassScannerBottomPanel(BuildContext context, {required Widget child}) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: child,
      ),
    );
    if (reduceMotion) {
      return inner;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: inner,
      ),
    );
  }

  Widget _processingHud(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CupertinoActivityIndicator(
              color: AppColors.white,
              radius: 14,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.qrScannerCheckingIn,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    if (reduceMotion) {
      return card;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: card,
      ),
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

    if (_scanned) {
      final AppLocalizations l10n = context.l10n;
      final String eventTitle = _event?.title ?? l10n.qrScannerGenericEventTitle;
      final String? checkedInTime = _checkedInAt == null
          ? null
          : '${_checkedInAt!.hour.toString().padLeft(2, '0')}:'
              '${_checkedInAt!.minute.toString().padLeft(2, '0')}';
      const double successMarkSize = 88;
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl + bottomSafe,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppMotion.standard,
                  curve: AppMotion.emphasized,
                  builder: (BuildContext context, double scale, Widget? child) {
                    return Transform.scale(
                      scale: 0.92 + 0.08 * scale,
                      child: Opacity(
                        opacity: scale,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: successMarkSize,
                    height: successMarkSize,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 24,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: AppMotion.emphasizedDuration,
                      curve: AppMotion.emphasized,
                      builder: (BuildContext context, double progress, Widget? child) {
                        return CustomPaint(
                          painter: _CheckmarkPainter(
                            progress: progress,
                            color: AppColors.primaryDark,
                            strokeWidth: 4,
                          ),
                          size: const Size(successMarkSize, successMarkSize),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl + AppSpacing.xs),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppMotion.standard,
                  curve: Interval(0.12, 1, curve: AppMotion.emphasized),
                  builder: (BuildContext context, double t, Widget? child) {
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: <Widget>[
                      Text(
                        l10n.qrScannerCheckedInTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.qrScannerWelcomeTo(eventTitle),
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (checkedInTime != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.qrScannerCheckedInAt(checkedInTime),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_checkInPointsAwarded > 0) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.eventsCheckInPointsEarned(_checkInPointsAwarded),
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: l10n.qrScannerDone,
                  child: PrimaryButton(
                    label: l10n.qrScannerDone,
                    enabled: true,
                    onPressed: _handleDone,
                  ),
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
          style: textTheme.titleLarge?.copyWith(
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
                    placeholderBuilder: _scannerLoadingLayer,
                    errorBuilder: _scannerErrorLayer,
                    tapToFocus: false,
                    scanWindow: kIsWeb ? null : scanRect,
                    scanWindowUpdateThreshold: 48,
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DimOutsideScanPainter(
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
                child: IgnorePointer(
                  ignoringSemantics: false,
                  child: Semantics(
                    container: true,
                    label: context.l10n.qrScannerPointCameraHint,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        CustomPaint(
                          size: Size.square(side),
                          painter: _SquareScanFramePainter(
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
                            final double travel = math.max(0, side - 2 * inset - 4);
                            final double top = inset + t * travel;
                            return Positioned(
                              left: inset,
                              right: inset,
                              top: top,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.85),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
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
                  child: _glassScannerChip(
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
                  child: _glassScannerBottomPanel(
                    context,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (_feedback != null) ...<Widget>[
                          Text(
                            _feedback!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: (_lastFeedbackStatus == null ||
                                      _isRecoverableScannerStatus(_lastFeedbackStatus!))
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                                minimumSize: Size.zero,
                                child: Text(
                                  context.l10n.qrScannerEnterManually,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textOnDark,
                                    fontWeight: FontWeight.w600,
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                                minimumSize: Size.zero,
                                child: Text(
                                  context.l10n.qrScannerRetryCamera,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textOnDarkMuted,
                                    fontWeight: FontWeight.w600,
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
                          style: textTheme.bodySmall?.copyWith(
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
                    child: Center(
                      child: _processingHud(context),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
