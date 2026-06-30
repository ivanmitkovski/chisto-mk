import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Full-width grouped table for filter rows (iOS Settings inset style).
class AppFilterInsetGroup extends StatelessWidget {
  const AppFilterInsetGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputFill.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
