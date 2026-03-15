import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.radius10,
        AppSpacing.md,
        0,
      ),
      child: Text(
        title,
        style: AppTypography.sectionHeader.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
