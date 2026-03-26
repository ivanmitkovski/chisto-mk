import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/domain/report_points.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

enum SubmittedDialogResult { viewReports, reportAnother }

class ReportSubmittedDialog extends StatefulWidget {
  const ReportSubmittedDialog({
    super.key,
    required this.categoryLabel,
    this.reportNumber,
    this.reportId,
    this.address,
    this.pointsAwarded = 0,
    this.isNewSite = false,
  });

  final String categoryLabel;
  final String? reportNumber;
  final String? reportId;
  final String? address;
  final int pointsAwarded;
  final bool isNewSite;

  @override
  State<ReportSubmittedDialog> createState() => _ReportSubmittedDialogState();
}

class _ReportSubmittedDialogState extends State<ReportSubmittedDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _checkController;
  late AnimationController _pointsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _pointsAnimation;
  bool _confettiLaunched = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: AppMotion.emphasizedDuration,
      vsync: this,
    );
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: AppMotion.emphasized,
    );
    _pointsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entryController.forward().then((_) {
        if (!mounted) return;
        _checkController.forward();
        AppHaptics.success();
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (mounted) _pointsController.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _checkController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_confettiLaunched) {
      _confettiLaunched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Confetti.launch(
          context,
          options: ConfettiOptions(
            particleCount: 48,
            spread: 55,
            angle: 90,
            startVelocity: 35,
            gravity: 0.4,
            decay: 0.94,
            y: 0.35,
            x: 0.5,
            colors: const <Color>[
              AppColors.primary,
              AppColors.primaryDark,
              AppColors.accentWarning,
              AppColors.white,
            ],
            scalar: 0.8,
          ),
        );
      });
    }
    final String categoryLabel = widget.categoryLabel;
    final String? address = widget.address;
    final int pointsAwarded = widget.pointsAwarded;
    final bool hasReportNumber =
        widget.reportNumber != null && widget.reportNumber!.isNotEmpty;
    final bool hasAddress = address != null && address.trim().isNotEmpty;
    final AppLocalizations l10n = context.l10n;

    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Semantics(
                    label: l10n.reportSubmittedSemanticsSuccess,
                    image: true,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _checkAnimation,
                            builder: (BuildContext context, Widget? child) {
                              return CustomPaint(
                                size: const Size(40, 40),
                                painter: _CheckmarkPainter(
                                  progress:
                                      _checkAnimation.value.clamp(0.0, 1.0),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.reportSubmittedTitle,
                    style: (AppTypography.textTheme.titleLarge ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasReportNumber) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.reportSubmittedSavedAs(widget.reportNumber!),
                      textAlign: TextAlign.center,
                      style: (AppTypography.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hasAddress
                        ? l10n.reportSubmittedBodyWithAddress(categoryLabel, address.trim())
                        : l10n.reportSubmittedBodyNoAddress(categoryLabel),
                    textAlign: TextAlign.center,
                    style: (AppTypography.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (widget.isNewSite) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.add_location_alt_rounded,
                          size: 16,
                          color: AppColors.accentInfo,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.reportSubmittedNewSiteBadge,
                          style: AppTypography.chipLabel.copyWith(
                            color: AppColors.accentInfo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedBuilder(
                    animation: _pointsAnimation,
                    builder: (BuildContext context, Widget? child) {
                      final double t =
                          _pointsAnimation.value.clamp(0.0, 1.0);
                      final bool hasAwarded = pointsAwarded > 0;
                      return Opacity(
                        opacity: t,
                        child: Transform.scale(
                          scale: 0.92 + (t * 0.08),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              gradient: hasAwarded
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: <Color>[
                                        AppColors.accentWarning
                                            .withValues(alpha: 0.18),
                                        AppColors.accentWarningDark
                                            .withValues(alpha: 0.12),
                                      ],
                                    )
                                  : null,
                              color: hasAwarded
                                  ? null
                                  : AppColors.textMuted.withValues(
                                      alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg),
                              border: hasAwarded
                                  ? Border.all(
                                      color: AppColors.accentWarning
                                          .withValues(alpha: 0.3),
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.emoji_events_rounded,
                                  size: 22,
                                  color: hasAwarded
                                      ? AppColors.accentWarningDark
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    hasAwarded
                                        ? l10n.reportSubmittedPointsEarned(pointsAwarded)
                                        : l10n.reportSubmittedPointsPending(ReportPoints.maxPending),
                                    style: AppTypography.chipLabel.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: hasAwarded
                                          ? AppColors.accentWarningDark
                                          : AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (widget.reportId != null &&
                      widget.reportId!.isNotEmpty) ...[
                    _ActionButton(
                      label: l10n.reportSubmittedViewThisReport,
                      primary: true,
                      onPressed: () {
                        AppHaptics.light();
                        Navigator.of(context).pop(widget.reportId);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActionButton(
                      label: l10n.reportSubmittedViewAllReports,
                      primary: false,
                      outlined: true,
                      onPressed: () {
                        AppHaptics.light();
                        Navigator.of(context)
                            .pop(SubmittedDialogResult.viewReports);
                      },
                    ),
                  ] else
                    _ActionButton(
                      label: l10n.reportSubmittedViewInMyReports,
                      primary: true,
                      onPressed: () {
                        AppHaptics.light();
                        Navigator.of(context)
                            .pop(SubmittedDialogResult.viewReports);
                      },
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionButton(
                    label: l10n.reportSubmittedReportAnother,
                    primary: false,
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.of(context)
                          .pop(SubmittedDialogResult.reportAnother);
                    },
                  ),
                ],
              ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: ReportCircleIconButton(
                      icon: Icons.close_rounded,
                      semanticLabel: l10n.semanticsClose,
                      onTap: () {
                        AppHaptics.tap();
                        Navigator.of(context)
                            .pop(SubmittedDialogResult.viewReports);
                      },
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

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final Paint paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.4, size.height * 0.74)
      ..lineTo(size.width * 0.82, size.height * 0.26);

    final Iterable<ui.PathMetric> metrics = path.computeMetrics();
    for (final ui.PathMetric metric in metrics) {
      final Path extracted = metric.extractPath(
        0,
        metric.length * math.min(progress, 1.0),
      );
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final bool primary;
  final bool outlined;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String semanticsLabel = label;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: outlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radius18),
                  ),
                ),
                child: Text(
                  label,
                  style: (AppTypography.textTheme.labelLarge ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              )
            : primary
                ? FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radius18),
                      ),
                    ),
                    child: Text(
                      label,
                      style: (AppTypography.textTheme.labelLarge ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: onPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      label,
                      style: (AppTypography.textTheme.labelLarge ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
      ),
    );
  }
}
