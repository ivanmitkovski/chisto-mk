import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_config.dart';
import 'package:flutter/material.dart';

/// Primary + back actions for the multi-step new-report flow.
class NewReportFlowBottomBar extends StatelessWidget {
  const NewReportFlowBottomBar({
    super.key,
    this.draftAutosaveLabel,
    required this.currentStage,
    required this.submitting,
    required this.submitPhase,
    required this.onPrimary,
    required this.onBack,
  });

  /// Localized hint when a draft was autosaved (e.g. "Saved just now"); empty hides the row.
  final String? draftAutosaveLabel;

  final ReportStage currentStage;
  final bool submitting;

  /// `'uploading' | 'creating' | 'sent' | null` while [submitting].
  final String? submitPhase;
  final VoidCallback onPrimary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bool showBack = currentStage != ReportStage.evidence;
    final bool isReviewStage = currentStage == ReportStage.review;
    final bool primaryLocked = submitting;
    final String primaryLabel = submitting
        ? (submitPhase == 'creating'
              ? context.l10n.reportFlowSubmitPhaseCreating
              : submitPhase == 'uploading'
              ? context.l10n.reportFlowSubmitPhaseUploading
              : submitPhase == 'sent'
              ? context.l10n.reportSubmitSentPending
              : context.l10n.reportFlowSubmitPhaseSubmitting)
        : currentStage.config(context.l10n).primaryActionLabel;
    final String primarySemanticsLabel = isReviewStage
        ? (submitting
              ? (submitPhase == 'sent'
                    ? context.l10n.reportSubmittedSemanticsSuccess
                    : context.l10n.reportIssueSubmit)
              : context.l10n.reportIssueSubmit)
        : context.l10n.semanticsNextStep(
            currentStage.config(context.l10n).shortLabel,
          );

    final String? autosave = draftAutosaveLabel?.trim();
    final bool showAutosave = autosave != null && autosave.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showAutosave) ...<Widget>[
            Center(
              child: Semantics(
                liveRegion: true,
                label: autosave,
                child: Text(
                  autosave,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: <Widget>[
              if (showBack) ...<Widget>[
                Expanded(
                  child: Semantics(
                    button: true,
                    label: context.l10n.commonBack,
                    child: OutlinedButton(
                      onPressed: primaryLocked ? null : onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.8),
                        ),
                        backgroundColor: AppColors.panelBackground,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radius18,
                          ),
                        ),
                      ),
                      child: Text(
                        context.l10n.commonBack,
                        style: AppTypography.reportsBottomBarButtonLabel(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                flex: showBack ? 2 : 1,
                child: Semantics(
                  button: true,
                  label: primarySemanticsLabel,
                  hint: primaryLocked
                      ? null
                      : (isReviewStage
                            ? context.l10n.reportFormPrimarySemanticsHintSubmit
                            : context.l10n.reportFormPrimarySemanticsHintNext),
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: primaryLocked ? null : onPrimary,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.42,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radius18,
                          ),
                        ),
                      ),
                      child: submitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    primaryLabel,
                                    style:
                                        AppTypography.reportsBottomBarButtonLabel(
                                          Theme.of(context).textTheme,
                                        ).copyWith(color: AppColors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                primaryLabel,
                                style:
                                    AppTypography.reportsBottomBarButtonLabel(
                                      Theme.of(context).textTheme,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
