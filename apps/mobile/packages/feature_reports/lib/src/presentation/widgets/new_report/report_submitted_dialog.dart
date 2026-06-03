import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/presentation/navigation/new_report_wizard_pop_result.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_submitted_checkmark_painter.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_submitted_dialog_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

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
  Timer? _pointsRevealDelay;

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
    _pointsController = AnimationController(
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
    _pointsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppHaptics.success(context);
      _entryController.forward().then((_) {
        if (!mounted) return;
        _checkController.forward();
        _pointsRevealDelay = Timer(AppMotion.fast, () {
          _pointsRevealDelay = null;
          if (mounted) _pointsController.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _pointsRevealDelay?.cancel();
    _pointsRevealDelay = null;
    _entryController.dispose();
    _checkController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    if (!_confettiLaunched) {
      _confettiLaunched = true;
      if (!MediaQuery.disableAnimationsOf(context)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Confetti.launch(
            context,
            options: const ConfettiOptions(
              particleCount: 48,
              spread: 55,
              angle: 90,
              startVelocity: 35,
              gravity: 0.4,
              decay: 0.94,
              y: 0.35,
              x: 0.5,
              colors: <Color>[
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: AppShadows.reportSubmittedHero(),
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
                                      progress: _checkAnimation.value.clamp(
                                        0.0,
                                        1.0,
                                      ),
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
                        style: AppTypography.textTheme.titleLarge!.copyWith(
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
                          style: AppTypography.textTheme.bodyMedium!.copyWith(
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
                            ? l10n.reportSubmittedBodyWithAddress(
                                categoryLabel,
                                address.trim(),
                              )
                            : l10n.reportSubmittedBodyNoAddress(categoryLabel),
                        textAlign: TextAlign.center,
                        style: AppTypography.textTheme.bodyMedium!.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (widget.isNewSite) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.add_location_alt_rounded,
                              size: 16,
                              color: AppColors.accentInfo,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.reportSubmittedNewSiteBadge,
                              style: AppTypography.chipLabel(textTheme)
                                  .copyWith(
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
                          final double t = _pointsAnimation.value.clamp(
                            0.0,
                            1.0,
                          );
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
                                            AppColors.accentWarning.withValues(
                                              alpha: 0.18,
                                            ),
                                            AppColors.accentWarningDark
                                                .withValues(alpha: 0.12),
                                          ],
                                        )
                                      : null,
                                  color: hasAwarded
                                      ? null
                                      : AppColors.textMuted.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
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
                                            ? l10n.reportSubmittedPointsEarned(
                                                pointsAwarded,
                                              )
                                            : l10n.reportSubmittedPointsPending,
                                        style:
                                            AppTypographySurfaces.reportsPillLabel(
                                              Theme.of(context).textTheme,
                                            ).copyWith(
                                              fontWeight: FontWeight.w700,
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
                        ReportSubmittedDialogActionButton(
                          label: l10n.reportSubmittedViewThisReport,
                          primary: true,
                          onPressed: () {
                            Navigator.of(context).pop(
                              NewReportWizardViewReport(widget.reportId!),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ReportSubmittedDialogActionButton(
                          label: l10n.reportSubmittedViewAllReports,
                          primary: false,
                          outlined: true,
                          onPressed: () {
                            Navigator.of(context).pop(
                              const NewReportWizardViewReports(),
                            );
                          },
                        ),
                      ] else
                        ReportSubmittedDialogActionButton(
                          label: l10n.reportSubmittedViewInMyReports,
                          primary: true,
                          onPressed: () {
                            Navigator.of(context).pop(
                              const NewReportWizardViewReports(),
                            );
                          },
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      ReportSubmittedDialogActionButton(
                        label: l10n.reportSubmittedReportAnother,
                        primary: false,
                        onPressed: () {
                          Navigator.of(context).pop(
                            const NewReportWizardReportAnother(),
                          );
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
                        Navigator.of(context).pop(
                          const NewReportWizardViewReports(),
                        );
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
