import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_config.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:flutter/material.dart';

/// Scrollable body for a report stage including optional API error banner.
class NewReportStageScrollBody extends StatelessWidget {
  const NewReportStageScrollBody({
    super.key,
    required this.currentStage,
    required this.apiError,
    required this.onDismissApiError,
    required this.onRetryApiError,
    required this.child,
  });

  final ReportStage currentStage;
  final AppError? apiError;
  final VoidCallback onDismissApiError;
  final VoidCallback? onRetryApiError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: PageStorageKey<ReportStage>(currentStage),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (apiError != null) ...<Widget>[
            ApiErrorBanner(
              message: apiError!.message,
              onDismiss: onDismissApiError,
              onRetry: apiError!.retryable ? onRetryApiError : null,
              detail: apiError!.retryable
                  ? context.l10n.errorBannerDraftSavedHint
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

/// Card chrome around each wizard step (title row, optional hint, divider, body).
class NewReportStageSurface extends StatelessWidget {
  const NewReportStageSurface({
    super.key,
    required this.stage,
    required this.isHighlighted,
    required this.reportFlowPrefsLoaded,
    required this.hasSeenReportHelpHint,
    required this.onDismissFlowHelpHint,
    required this.onPressedHelp,
    required this.child,
  });

  final ReportStage stage;
  final bool isHighlighted;
  final bool reportFlowPrefsLoaded;
  final bool hasSeenReportHelpHint;
  final VoidCallback onDismissFlowHelpHint;
  final VoidCallback onPressedHelp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReportStageConfig cfg = stage.config(context.l10n);

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isHighlighted
              ? AppColors.accentDanger.withValues(alpha: 0.32)
              : AppColors.divider.withValues(alpha: 0.7),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(cfg.infoTitle, style: AppTypography.sectionHeader),
              ),
              Semantics(
                button: true,
                label: context.l10n.semanticsAboutStep(cfg.infoTitle),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.info_outline_rounded),
                  color: AppColors.textSecondary,
                  tooltip: context.l10n.newReportTooltipAboutStep,
                  onPressed: onPressedHelp,
                ),
              ),
            ],
          ),
          if (reportFlowPrefsLoaded &&
              !hasSeenReportHelpHint &&
              stage == ReportStage.evidence) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.reportFlowHelpHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textMuted,
                  tooltip: context.l10n.newReportTooltipDismiss,
                  onPressed: onDismissFlowHelpHint,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Divider(color: AppColors.divider.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
