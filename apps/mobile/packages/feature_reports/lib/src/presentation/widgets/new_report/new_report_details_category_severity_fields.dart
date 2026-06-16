import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/l10n/report_category_l10n.dart';
import 'package:feature_reports/src/presentation/l10n/report_severity_l10n.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_severity_slider.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:feature_reports/src/presentation/widgets/report_category_picker.dart';
import 'package:flutter/material.dart';

class NewReportDetailsCategoryField extends StatelessWidget {
  const NewReportDetailsCategoryField({
    super.key,
    required this.draft,
    required this.attemptedStages,
    required this.onCategorySelected,
  });

  final ReportDraft draft;
  final Set<ReportStage> attemptedStages;
  final ValueChanged<ReportCategory> onCategorySelected;

  void _openCategoryPicker(BuildContext context) {
    showReportCategoryPicker(
      context,
      selected: draft.category,
      onSelected: onCategorySelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCategoryError =
        attemptedStages.contains(ReportStage.details) && !draft.hasCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.reportReviewCategoryTitle,
          style: AppTypographySurfaces.reportsFormFieldLabel(
            Theme.of(context).textTheme,
            color: hasCategoryError ? AppColors.error : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: context.l10n.reportSelectCategorySemantic,
          value: draft.category?.localizedTitle(context.l10n) ?? '',
          child: ReportActionTile(
            icon: draft.category?.icon ?? Icons.category_outlined,
            title:
                draft.category?.localizedTitle(context.l10n) ??
                context.l10n.reportReviewCategoryTitle,
            subtitle: draft.category == null
                ? context.l10n.reportReviewChooseCategory
                : draft.category!.localizedDescription(context.l10n),
            tone: hasCategoryError
                ? ReportSurfaceTone.danger
                : ReportSurfaceTone.neutral,
            trailing: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
            onTap: () => _openCategoryPicker(context),
          ),
        ),
      ],
    );
  }
}

class NewReportDetailsSeverityField extends StatelessWidget {
  const NewReportDetailsSeverityField({
    super.key,
    required this.draft,
    required this.onSeverityChanged,
  });

  final ReportDraft draft;
  final ValueChanged<int> onSeverityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.reportReviewSeverityTitle,
          style: AppTypographySurfaces.reportsFormFieldLabel(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: AppColors.inputBorder.withValues(alpha: 0.8),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                reportSeverityDisplayLabel(context.l10n, draft.severity),
                style: AppTypographySurfaces.reportsSliderValue(
                  Theme.of(context).textTheme,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportSeveritySlider(
                value: draft.severity,
                semanticsLabel: context.l10n.reportReviewSeverityTitle,
                semanticsValue: reportSeverityDisplayLabel(
                  context.l10n,
                  draft.severity,
                ),
                onChanged: onSeverityChanged,
              ),
              ReportSeveritySliderLabels(
                lowLabel: context.l10n.reportSeverityLow,
                criticalLabel: context.l10n.reportSeverityCritical,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
