import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_shadows.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';

class StickyBottomCTA extends StatelessWidget {
  const StickyBottomCTA({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.appBackground,
          boxShadow: AppShadows.sheet(Theme.of(context).colorScheme),
        ),
        child: PrimaryButton(label: label, onPressed: onPressed),
      ),
    );
  }
}
