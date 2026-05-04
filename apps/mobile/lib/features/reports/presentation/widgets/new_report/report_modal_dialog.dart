import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Modal shell aligned with [ReportingCooldownDialog] and [ReportSubmittedDialog]
/// (panel surface, card radius, divider border, soft shadow).
class ReportModalDialog extends StatelessWidget {
  const ReportModalDialog({
    super.key,
    this.leading,
    required this.title,
    required this.footer,
    required this.child,
  });

  /// Optional hero icon (e.g. draft / timer), centered above the title.
  final Widget? leading;

  final String title;
  final Widget footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = AppTypography.textTheme;
    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.95)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                Center(child: leading!),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              child,
              const SizedBox(height: AppSpacing.xl),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}
