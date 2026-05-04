import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/cleanup_effort_l10n.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
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
    final TextStyle labelStyle = AppTypography.reportsFormFieldLabel(
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
                  AppHaptics.light();
                  onCleanupEffort(effort);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.14),
                labelStyle: AppTypography.badgeLabel.copyWith(
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
