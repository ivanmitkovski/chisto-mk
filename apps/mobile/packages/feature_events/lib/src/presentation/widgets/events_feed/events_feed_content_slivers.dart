part of 'package:feature_events/src/presentation/screens/events_feed_screen.dart';

extension EventsFeedContentSlivers on EventsFeedScreenState {
  List<Widget> buildEventsFeedContentSlivers({
    required BuildContext context,
    required ColorScheme colorScheme,
    required double bottomSafePadding,
    required List<EcoEvent> filtered,
    required EcoEvent? hero,
    required bool showSections,
    required bool showHero,
    required EcoEvent? featuredHeroForList,
    required List<EcoEvent> happeningNowRows,
    required List<EcoEvent> comingUpRows,
    required List<EcoEvent> listToShow,
    required bool isOrganizer,
    required String phase,
    required double? userLatitude,
    required double? userLongitude,
    required bool animateListEntrance,
  }) {
    return <Widget>[
      if (phase == 'content' && _feed.repository.isShowingStaleCachedEvents)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Semantics(
              label: context.l10n.eventsFeedOfflineStaleBanner,
              container: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        CupertinoIcons.wifi_slash,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          context.l10n.eventsFeedOfflineStaleBanner,
                          style: AppTypography.eventsInlineInfoBanner(
                            Theme.of(context).textTheme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

      if (phase == 'error')
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            error: _feed.initialLoadError!,
            onRetry: _retryInitialLoad,
          ),
        )
      else ...<Widget>[
        if (showHero)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: HeroEventCard(
                event: hero!,
                onTap: () => _navigateToDetail(hero),
              ),
            ),
          ),

        if (showSections && !_feed.calendarView) ...<Widget>[
          if (happeningNowRows.isNotEmpty) ...<Widget>[
            SectionHeader(title: context.l10n.eventsFeedHappeningNow),
            EventsSliverList(
              events: happeningNowRows,
              onTap: _navigateToDetail,
              userLatitude: userLatitude,
              userLongitude: userLongitude,
              startIndex: 0,
              animateEntrance: animateListEntrance,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
          if (comingUpRows.isNotEmpty) ...<Widget>[
            SectionHeader(title: context.l10n.eventsFeedComingUp),
            EventsSliverList(
              events: comingUpRows,
              onTap: _navigateToDetail,
              userLatitude: userLatitude,
              userLongitude: userLongitude,
              startIndex: happeningNowRows.length,
              animateEntrance: animateListEntrance,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
          if (_feed.recentlyCompleted.isNotEmpty) ...<Widget>[
            SectionHeader(title: context.l10n.eventsFeedRecentlyCompleted),
            EventsSliverList(
              events: _feed.recentlyCompleted.take(3).toList(),
              onTap: _navigateToDetail,
              userLatitude: userLatitude,
              userLongitude: userLongitude,
              startIndex: happeningNowRows.length + comingUpRows.length,
              animateEntrance: animateListEntrance,
            ),
          ],
          if (happeningNowRows.isEmpty &&
              comingUpRows.isEmpty &&
              _feed.recentlyCompleted.isEmpty &&
              hero == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EventsEmptyState(
                filter: _feed.activeFilter,
                showClearFilters: _feed.hasActiveFilters,
                onClearFilters: _feed.hasActiveFilters
                    ? _resetFiltersAndRefresh
                    : null,
                onCreateEvent: _navigateToCreate,
              ),
            ),
        ] else if (!showSections && !_feed.calendarView) ...<Widget>[
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _feed.searchQuery.isNotEmpty
                  ? SearchEmptyState(
                      query: _feed.searchQuery,
                      onClearSearch: _clearSearchOnly,
                      onCreateEvent: _navigateToCreate,
                    )
                  : EventsEmptyState(
                      filter: _feed.activeFilter,
                      showClearFilters: _feed.hasActiveFilters,
                      onClearFilters: _feed.hasActiveFilters
                          ? _resetFiltersAndRefresh
                          : null,
                      onCreateEvent: _navigateToCreate,
                    ),
            )
          else
            EventsSliverList(
              events: listToShow,
              onTap: _navigateToDetail,
              userLatitude: userLatitude,
              userLongitude: userLongitude,
              animateEntrance: animateListEntrance,
            ),
        ],

        if (_feed.calendarView)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: EventsCalendarView(
                events: filtered,
                onEventTap: _navigateToDetail,
                hasMorePages: _feed.repository.hasMoreEvents,
                onRequestMoreFromServer: _calendarLoadMore,
              ),
            ),
          ),
      ],

      SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.xxl + bottomSafePadding),
      ),
    ];
  }
}
