import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class FeedNoLocationState extends StatelessWidget {
  const FeedNoLocationState({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 30,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.feedNoLocationTitle,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateTitle(textTheme),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.feedNoLocationHint,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateSubtitle(
                textTheme,
              ).copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: context.l10n.feedNoLocationOpenSettings,
              onPressed: onOpenSettings,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}
