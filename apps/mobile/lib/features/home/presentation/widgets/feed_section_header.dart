import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

class FeedSectionHeader extends StatelessWidget {
  const FeedSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(
        'Pollution sites',
        style: AppTypography.sectionHeader.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
