import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage_config.dart';
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
              error: apiError,
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
    final TextTheme textTheme = Theme.of(context).textTheme;
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
              ? AppColors.error.withValues(alpha: 0.32)
              : AppColors.divider.withValues(alpha: 0.7),
        ),
        boxShadow: AppShadows.card(Theme.of(context).colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  cfg.infoTitle,
                  style: AppTypography.sectionHeader(textTheme),
                ),
              ),
              Semantics(
                button: true,
                label: context.l10n.semanticsAboutStep(cfg.infoTitle),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
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
                    style: AppTypographySurfaces.reportsPhotoGridHint(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
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
