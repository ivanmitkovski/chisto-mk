import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';

/// Trailing row for the feed [SliverList] when loading more or retrying.
class FeedLoadMoreRow extends StatelessWidget {
  const FeedLoadMoreRow({
    super.key,
    required this.loadFailed,
    required this.onRetry,
  });

  final bool loadFailed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loadFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.l10n.feedRetryLoadingMore),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.l10n.feedLoadingMoreSemantic,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: AppLoadingIndicator(size: AppLoadingIndicatorSize.sm),
          ),
        ),
      ),
    );
  }
}
