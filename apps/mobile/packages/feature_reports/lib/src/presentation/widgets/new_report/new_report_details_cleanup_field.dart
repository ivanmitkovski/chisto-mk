import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/l10n/cleanup_effort_l10n.dart';
import 'package:flutter/material.dart';

class NewReportDetailsCleanupEffortField extends StatelessWidget {
  const NewReportDetailsCleanupEffortField({
    super.key,
    required this.draft,
    required this.onCleanupEffort,
  });

  final ReportDraft draft;
  final ValueChanged<CleanupEffort> onCleanupEffort;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle labelStyle = AppTypographySurfaces.reportsFormFieldLabel(
      Theme.of(context).textTheme,
    );
    final CleanupEffort? current = draft.cleanupEffort;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(context.l10n.reportReviewCleanupEffortTitle, style: labelStyle),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: CleanupEffort.values.map((CleanupEffort effort) {
            final bool selected = current == effort;
            return Semantics(
              button: true,
              label: effort.localizedLabel(context.l10n),
              hint: context.l10n.reportCleanupEffortChipHint,
              child: ChoiceChip(
                label: Text(effort.localizedLabel(context.l10n)),
                selected: selected,
                onSelected: (_) {
                  onCleanupEffort(effort);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.14),
                labelStyle: AppTypography.badgeLabel(textTheme).copyWith(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.inputFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primaryDark.withValues(alpha: 0.5)
                        : AppColors.divider.withValues(alpha: 0.9),
                    width: 0.9,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
