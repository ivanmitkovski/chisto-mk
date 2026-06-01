import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class FeedSectionHeader extends StatelessWidget {
  const FeedSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: context.l10n.feedPollutionFeedTitle,
      variant: AppSectionHeaderVariant.feed,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
    );
  }
}
