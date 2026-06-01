import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_upload_prep_progress.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage_config.dart';
import 'package:flutter/material.dart';

/// Primary + back actions for the multi-step new-report flow.
class NewReportFlowBottomBar extends StatelessWidget {
  const NewReportFlowBottomBar({
    super.key,
    this.draftAutosaveLabel,
    required this.currentStage,
    required this.submitting,
    required this.submitPhase,
    this.uploadPrepProgress,
    required this.onPrimary,
    required this.onBack,
  });

  /// Localized hint when a draft was autosaved (e.g. "Saved just now"); empty hides the row.
  final String? draftAutosaveLabel;

  final ReportStage currentStage;
  final bool submitting;

  /// `'uploading' | 'creating' | 'sent' | null` while [submitting].
  final String? submitPhase;

  /// When photos are being compressed before HTTP upload (done ≤ total).
  final ReportUploadPrepProgress? uploadPrepProgress;
  final VoidCallback onPrimary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bool showBack = currentStage != ReportStage.evidence;
    final bool isReviewStage = currentStage == ReportStage.review;
    final bool primaryLocked = submitting;
    final String? prepLabel =
        (uploadPrepProgress != null &&
            submitPhase == 'uploading' &&
            uploadPrepProgress!.total > 0)
        ? context.l10n.reportFlowSubmitPhaseUploadingProgress(
            uploadPrepProgress!.completed,
            uploadPrepProgress!.total,
          )
        : null;
    final String primaryLabel = submitting
        ? (submitPhase == 'creating'
              ? context.l10n.reportFlowSubmitPhaseCreating
              : submitPhase == 'uploading'
              ? (prepLabel ?? context.l10n.reportFlowSubmitPhaseUploading)
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
                  style: AppTypographySurfaces.reportsBottomBarStep(
                    Theme.of(context).textTheme,
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
                    child: AppButton.outlined(
                      label: context.l10n.commonBack,
                      onPressed: onBack,
                      enabled: !primaryLocked,
                      expand: true,
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
                  child: AppButton.primary(
                    label: primaryLabel,
                    onPressed: onPrimary,
                    enabled: !primaryLocked,
                    isLoading: submitting,
                    expand: true,
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
