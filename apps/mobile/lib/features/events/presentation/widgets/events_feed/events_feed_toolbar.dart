part of 'package:chisto_mobile/features/events/presentation/screens/events_feed_screen.dart';

extension EventsFeedToolbar on EventsFeedScreenState {
  List<Widget> buildEventsFeedToolbarSlivers({
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
  }) {
    return <Widget>[
                        // Same pattern as [ReportsListScreen]: static headline + tools (no collapsing app bar).
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    context.l10n.eventsFeedTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                                if (isOrganizer)
                                  Semantics(
                                    button: true,
                                    label: context.l10n.eventsOrganizerDashboardTitle,
                                    child: IconButton(
                                      tooltip:
                                          context.l10n.eventsOrganizerDashboardTitle,
                                      onPressed: () {
                                        EventsNavigation.openOrganizerDashboard(
                                          context,
                                        );
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.chart_bar_alt_fill,
                                      ),
                                    ),
                                  ),
                                if (isOrganizer) const SizedBox(width: AppSpacing.xs),
                                Semantics(
                                  button: true,
                                  label: context.l10n.eventsFeedCreateSemantic,
                                  child: IconButton(
                                    tooltip: context.l10n.eventsFeedCreateSemantic,
                                    onPressed: _navigateToCreate,
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Search + filter + view toggle ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              AppSpacing.sm,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: AppCupertinoSearchField(
                                    controller: _feed.searchController,
                                    focusNode: _searchFocusNode,
                                    toolbarHeight:
                                        AppSpacing.eventsFeedToolbarControlSize,
                                    placeholder:
                                        context.l10n.eventsFeedSearchPlaceholder,
                                    semanticLabel:
                                        context.l10n.eventsFeedSearchPlaceholder,
                                    onChanged: _onSearchChanged,
                                    onSubmitted: () {
                                      unawaited(
                                        _feed.rememberSearch(
                                          _feed.searchController.text,
                                        ),
                                      );
                                    },
                                    onClear: () {
                                      unawaited(() async {
                                        final bool ok =
                                            await _feed.clearSearchField();
                                        if (!ok && context.mounted) {
                                          logEventsDiagnostic(
                                            'events_feed_refresh_failed',
                                          );
                                          AppSnack.show(
                                            context,
                                            message: context
                                                .l10n.eventsFeedRefreshFailed,
                                            type: AppSnackType.warning,
                                          );
                                        }
                                      }());
                                    },
                                    autocorrect: false,
                                    smartDashesType: SmartDashesType.disabled,
                                    smartQuotesType: SmartQuotesType.disabled,
                                    enableIMEPersonalizedLearning: false,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Semantics(
                                  button: true,
                                  label: context.l10n.eventsFilterSheetTitle,
                                  child: Material(
                                    color: AppColors.transparent,
                                    child: InkWell(
                                      onTap: _openFilterSheet,
                                      customBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: Container(
                                        width: AppSpacing.eventsFeedToolbarControlSize,
                                        height:
                                            AppSpacing.eventsFeedToolbarControlSize,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _feed.hasActiveFilters
                                              ? AppColors.feedPillSelectedFill
                                              : colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusMd,
                                          ),
                                          border: Border.all(
                                            color: _feed.hasActiveFilters
                                                ? AppColors.feedPillSelectedBorder
                                                : colorScheme.outlineVariant.withValues(
                                                    alpha: 0.6,
                                                  ),
                                          ),
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          fit: StackFit.expand,
                                          alignment: Alignment.center,
                                          children: <Widget>[
                                            Icon(
                                              CupertinoIcons.slider_horizontal_3,
                                              size: 18,
                                              color: _feed.hasActiveFilters
                                                  ? AppColors.feedPillSelectedForeground
                                                  : colorScheme.onSurfaceVariant,
                                            ),
                                            if (_feed.hasActiveFilters)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.feedPillSelectedForeground,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                ViewToggleButton(
                                  icon: CupertinoIcons.square_list_fill,
                                  selected: !_feed.calendarView,
                                  tooltip: context.l10n.eventsFeedViewListToggle,
                                  onTap: () {
                                    _feed.setCalendarView(false);
                                  },
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                ViewToggleButton(
                                  icon: CupertinoIcons.calendar,
                                  selected: _feed.calendarView,
                                  tooltip: context.l10n.eventsFeedViewCalendarToggle,
                                  onTap: () {
                                    _feed.setCalendarView(true);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (!_feed.calendarView && _feed.searchQuery.trim().isEmpty)
                          SliverToBoxAdapter(
                            child: RecentSearchesShelf(
                              recentSearches: _feed.recentSearches,
                              onSearchTap: _onRecentSearchTap,
                            ),
                          ),

                        // ── Filter chips ──
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: EventsFilterChips(
                              active: _feed.activeFilter,
                              onSelected: _onFilterChanged,
                            ),
                          ),
                        ),

    ];
  }
}
