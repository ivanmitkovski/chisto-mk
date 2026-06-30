import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class FeedCaughtUpFooter extends StatelessWidget {
  const FeedCaughtUpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: AppSpacing.xl,
            height: AppSpacing.sheetHandleHeight,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.feedCaughtUpTitle,
            style: AppTypography.homeFeedCaughtUpTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.l10n.feedCaughtUpSubtitle,
            style: AppTypography.homeFeedCaughtUpSubtitle(
              Theme.of(context).textTheme,
            ),
          ),
        ],
      ),
    );
  }
}
