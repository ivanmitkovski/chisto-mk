import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.radius10,
        AppSpacing.md,
        0,
      ),
      child: Text(
        title,
        style: AppTypography.sectionHeader(textTheme).copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
