import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Status filters on the reports list — matches [FeedFilterBar] chip styling.
class ReportFilterChip extends StatelessWidget {
  const ReportFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.reportListFilterChipSemantic(label, selected ? 1 : 0),
      hint: l10n.reportListFilterChipHint(label),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        materialTapTargetSize: dense
            ? MaterialTapTargetSize.shrinkWrap
            : MaterialTapTargetSize.padded,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryDark.withValues(alpha: 0.12),
        labelStyle: AppTypography.chipLabel.copyWith(
          fontSize: dense ? 12.5 : null,
          color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected
              ? AppColors.primaryDark.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.xs + 2 : AppSpacing.sm,
          vertical: dense ? 3 : AppSpacing.xxs,
        ),
      ),
    );
  }
}
