import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Outcome shown after [EventCleanupEvidenceScreen] finishes saving after photos.
enum CleanupEvidenceSaveOutcome {
  success,
  failure,
}

/// Full-screen dimmed overlay with a centered card (same interaction model as
/// [EventSuccessDialog] after creating an event).
class CleanupEvidenceSaveResultDialog extends StatefulWidget {
  const CleanupEvidenceSaveResultDialog({
    super.key,
    required this.outcome,
    this.failureDetail,
  });

  final CleanupEvidenceSaveOutcome outcome;
  final String? failureDetail;

  @override
  State<CleanupEvidenceSaveResultDialog> createState() =>
      _CleanupEvidenceSaveResultDialogState();
}

class _CleanupEvidenceSaveResultDialogState
    extends State<CleanupEvidenceSaveResultDialog>
    with TickerProviderStateMixin {
  late final AnimationController _containerController;
  late final AnimationController _checkController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _checkAnimation;

  bool get _isSuccess => widget.outcome == CleanupEvidenceSaveOutcome.success;

  String _failureBodyText(BuildContext context) {
    final String trimmed = widget.failureDetail?.trim() ?? '';
    return trimmed.isNotEmpty
        ? trimmed
        : context.l10n.eventsMutationFailedGeneric;
  }

  @override
  void initState() {
    super.initState();
    _containerController = AnimationController(
      vsync: this,
      duration: AppMotion.emphasizedDuration,
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _containerController,
      curve: AppMotion.spring,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _containerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: AppMotion.emphasized,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _containerController.value = 1.0;
        if (_isSuccess) {
          _checkController.value = 1.0;
          AppHaptics.success();
        } else {
          AppHaptics.warning();
        }
      } else {
        _containerController.forward().then((_) {
          if (!mounted) return;
          if (_isSuccess) {
            _checkController.forward();
            AppHaptics.success();
          } else {
            AppHaptics.warning();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _containerController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 80,
                  height: 80,
                  child: _isSuccess
                      ? Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                ),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _checkAnimation,
                              builder: (BuildContext context, Widget? child) {
                                return CustomPaint(
                                  size: const Size(36, 36),
                                  painter: _CheckPainter(
                                    progress: _checkAnimation.value,
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            size: 44,
                            color: AppColors.error,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isSuccess
                      ? context.l10n.eventsEvidenceSaveSuccessTitle
                      : context.l10n.eventsEvidenceSaveFailureTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.eventsSheetTitle(textTheme),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isSuccess
                      ? context.l10n.eventsEvidenceSaveSuccessBody
                      : context.l10n.eventsEvidenceSaveFailureBody(
                          _failureBodyText(context),
                        ),
                  textAlign: TextAlign.center,
                  style: AppTypography.eventsSupportingCaption(textTheme).copyWith(
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    child: Text(
                      _isSuccess
                          ? context.l10n.commonGotIt
                          : context.l10n.commonTryAgain,
                      style: AppTypography.eventsPrimaryButtonLabel(textTheme),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});

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
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.8, size.height * 0.28);

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
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
