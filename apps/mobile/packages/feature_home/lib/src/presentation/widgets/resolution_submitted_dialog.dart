import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ResolutionSubmittedDialogResult { viewReports, done }

class ResolutionSubmittedDialog extends StatefulWidget {
  const ResolutionSubmittedDialog({super.key});

  static Future<ResolutionSubmittedDialogResult?> show(BuildContext context) {
    return showDialog<ResolutionSubmittedDialogResult>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const ResolutionSubmittedDialog(),
    );
  }

  @override
  State<ResolutionSubmittedDialog> createState() =>
      _ResolutionSubmittedDialogState();
}

class _ResolutionSubmittedDialogState extends State<ResolutionSubmittedDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: AppMotion.emphasizedDuration,
      vsync: this,
    );
    _checkController = AnimationController(
      duration: AppMotion.successCheckReveal,
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: AppMotion.emphasized,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppHaptics.success(context);
      unawaited(_entryController.forward().then((_) {
        if (mounted) _checkController.forward();
      }));
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
              boxShadow: AppShadows.reportSubmittedHero(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  label: l10n.resolutionSubmittedSemanticsSuccess,
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
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            boxShadow: AppShadows.reportSubmittedIcon(),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _checkAnimation,
                          builder: (BuildContext context, Widget? child) {
                            return CustomPaint(
                              size: const Size(40, 40),
                              painter: ReportSubmittedCheckmarkPainter(
                                progress: _checkAnimation.value.clamp(0.0, 1.0),
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
                  l10n.resolutionSubmittedTitle,
                  style: AppTypography.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.resolutionSubmittedBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodyMedium!.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ReportSubmittedDialogActionButton(
                  label: l10n.resolutionSubmittedViewMyReports,
                  primary: true,
                  onPressed: () {
                    Navigator.of(context).pop(
                      ResolutionSubmittedDialogResult.viewReports,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ReportSubmittedDialogActionButton(
                  label: l10n.resolutionSubmittedDone,
                  primary: false,
                  onPressed: () {
                    Navigator.of(context).pop(ResolutionSubmittedDialogResult.done);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> handleResolutionSubmittedDialogResult(
  BuildContext context,
  ResolutionSubmittedDialogResult? result,
) async {
  if (result == ResolutionSubmittedDialogResult.viewReports &&
      context.mounted) {
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go('/reports');
    }
  }
}
