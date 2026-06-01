import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Warning callout when GET check-conflict reports an overlapping event.
class EditEventScheduleConflictCallout extends StatelessWidget {
  const EditEventScheduleConflictCallout({super.key, required this.bodyText});

  final String bodyText;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      label: bodyText,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accentWarning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.accentWarning.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          bodyText,
          style: AppTypography.eventsSupportingCaption(
            textTheme,
          ).copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
