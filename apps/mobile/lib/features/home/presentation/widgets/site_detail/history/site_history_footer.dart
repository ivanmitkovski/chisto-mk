import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:flutter/material.dart';

enum SiteHistoryFooterMode { none, loadingMore, endOfList }

class SiteHistoryFooter extends StatelessWidget {
  const SiteHistoryFooter({super.key, required this.mode});

  final SiteHistoryFooterMode mode;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case SiteHistoryFooterMode.none:
        return const SizedBox.shrink();
      case SiteHistoryFooterMode.loadingMore:
        return Semantics(
          liveRegion: true,
          label: context.l10n.siteHistoryLoadingMore,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AppLoadingIndicator(),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.siteHistoryLoadingMore,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        );
      case SiteHistoryFooterMode.endOfList:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Center(
            child: Text(
              context.l10n.siteHistoryEndOfList,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
        );
    }
  }
}
