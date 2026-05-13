import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_config.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/stage_chip.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';

/// Top title row + horizontal stage stepper for the new-report wizard.
class NewReportFlowHeader extends StatelessWidget {
  const NewReportFlowHeader({
    super.key,
    required this.title,
    required this.currentStage,
    required this.currentStageIndex,
    required this.isStageComplete,
    required this.canNavigateToStage,
    required this.onBackFromEvidence,
    required this.onBackToPreviousStage,
    required this.onTapStage,
    this.showDraftRestoredChip = false,
  });

  final String title;
  final ReportStage currentStage;
  final int currentStageIndex;
  final bool Function(ReportStage stage) isStageComplete;
  final bool Function(ReportStage stage) canNavigateToStage;
  final VoidCallback onBackFromEvidence;
  final VoidCallback onBackToPreviousStage;
  final void Function(ReportStage stage) onTapStage;
  final bool showDraftRestoredChip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Semantics(
              button: true,
              label: currentStage == ReportStage.evidence
                  ? context.l10n.reportBackSemantic
                  : context.l10n.reportPreviousStepSemantic,
              child: AppBackButton(
                backgroundColor: AppColors.inputFill,
                onPressed: () {
                  if (currentStage == ReportStage.evidence) {
                    onBackFromEvidence();
                    return;
                  }
                  onBackToPreviousStage();
                },
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            ReportStatePill(
              label: '${currentStageIndex + 1}/${ReportStage.values.length}',
              tone: currentStage == ReportStage.review
                  ? ReportSurfaceTone.success
                  : ReportSurfaceTone.neutral,
            ),
          ],
        ),
        if (showDraftRestoredChip) ...<Widget>[
          SizedBox(height: AppSpacing.sm),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.reportSurfaceMint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.reportBannerSuccessBorder),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  context.l10n.reportDraftRestoredChip,
                  style: AppTypography.reportsBadgeLabel(
                    Theme.of(context).textTheme,
                  ).copyWith(color: AppColors.primaryDark),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: Row(
              children: ReportStage.values.asMap().entries.map((
                MapEntry<int, ReportStage> entry,
              ) {
                final ReportStage stage = entry.value;
                return Expanded(
                  child: StageChip(
                    label: stage.config(context.l10n).shortLabel,
                    isCurrent: stage == currentStage,
                    isComplete: isStageComplete(stage),
                    isEnabled: canNavigateToStage(stage),
                    onTap: () => onTapStage(stage),
                    stepIndex: entry.key,
                    totalSteps: ReportStage.values.length,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
