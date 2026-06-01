import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_search_result_tile.dart';
import 'package:flutter/material.dart';

/// Search results / empty / error / loading body shown when chat search mode is open.
class EventChatSearchPanel extends StatelessWidget {
  const EventChatSearchPanel({
    super.key,
    required this.searchLoading,
    required this.searchError,
    required this.lastSearchQuery,
    required this.searchHasMore,
    required this.merged,
    required this.showLocalBanner,
    required this.onRetrySearch,
    required this.onLoadMoreSearch,
    required this.onSelectHit,
  });

  final bool searchLoading;
  final bool searchError;
  final String lastSearchQuery;
  final bool searchHasMore;
  final List<EventChatMessage> merged;
  final bool showLocalBanner;
  final Future<void> Function() onRetrySearch;
  final Future<void> Function() onLoadMoreSearch;
  final void Function(EventChatMessage message) onSelectHit;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (searchLoading && merged.isEmpty && !searchError) {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: AppLoadingIndicator(size: AppLoadingIndicatorSize.lg),
        ),
      );
    }

    if (searchError && merged.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.l10n.eventChatSearchFailed,
                textAlign: TextAlign.center,
                style: AppTypography.eventsBodyMediumSecondary(textTheme),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                label: context.l10n.eventsDetailRetryRefresh,
                onPressed: () => unawaited(onRetrySearch()),
                enabled: lastSearchQuery.length >= 2,
                expand: false,
              ),
            ],
          ),
        ),
      );
    }

    if (lastSearchQuery.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            context.l10n.eventChatSearchMinChars,
            textAlign: TextAlign.center,
            style: AppTypography.eventsBodyMuted(textTheme),
          ),
        ),
      );
    }

    if (!searchLoading && merged.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            context.l10n.eventChatSearchNoResults,
            textAlign: TextAlign.center,
            style: AppTypography.eventsBodyMuted(textTheme),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount:
          merged.length + (searchHasMore ? 1 : 0) + (showLocalBanner ? 1 : 0),
      itemBuilder: (BuildContext context, int i) {
        if (showLocalBanner && i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Material(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  context.l10n.eventChatSearchIncludingLocalMatches,
                  style: AppTypography.eventsCaptionStrong(
                    textTheme,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }
        final int offset = showLocalBanner ? 1 : 0;
        final int j = i - offset;
        if (j == merged.length) {
          return Center(
            child: AppButton.text(
              label: context.l10n.eventChatSearchLoadMore,
              onPressed: () => unawaited(onLoadMoreSearch()),
              enabled: !searchLoading,
            ),
          );
        }
        final EventChatMessage m = merged[j];
        return ChatSearchResultTile(
          message: m,
          query: lastSearchQuery,
          onTap: () => onSelectHit(m),
        );
      },
    );
  }
}
