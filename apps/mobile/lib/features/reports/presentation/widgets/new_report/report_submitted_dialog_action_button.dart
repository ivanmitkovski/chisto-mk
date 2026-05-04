import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class ReportSubmittedDialogActionButton extends StatelessWidget {
  const ReportSubmittedDialogActionButton({
    super.key,
    required this.label,
    required this.primary,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final bool primary;
  final bool outlined;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: outlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radius18),
                  ),
                ),
                child: Text(
                  label,
                  style:
                      (AppTypography.textTheme.labelLarge ?? const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                ),
              )
            : primary
            ? FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radius18),
                  ),
                ),
                child: Text(
                  label,
                  style:
                      (AppTypography.textTheme.labelLarge ?? const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                ),
              )
            : TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(
                  label,
                  style:
                      (AppTypography.textTheme.labelLarge ?? const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                ),
              ),
      ),
    );
  }
}
