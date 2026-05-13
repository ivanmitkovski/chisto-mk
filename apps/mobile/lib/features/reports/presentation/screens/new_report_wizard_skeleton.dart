import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/theme/report_tokens.dart';
import 'package:flutter/material.dart';

/// Lightweight placeholder while the wizard restores a draft from SQLite.
class NewReportWizardSkeleton extends StatelessWidget {
  const NewReportWizardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: ReportTokens.evidenceAspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: AppColors.reportDividerMedium),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 14,
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: ReportTokens.photoGridSpacing,
              crossAxisSpacing: ReportTokens.photoGridSpacing,
              physics: const NeverScrollableScrollPhysics(),
              children: List<Widget>.generate(3, (_) {
                return AspectRatio(
                  aspectRatio: ReportTokens.photoGridAspectRatio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.reportDividerLight),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
