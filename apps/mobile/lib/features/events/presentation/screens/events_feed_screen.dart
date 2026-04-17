import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/controllers/events_feed_controller.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_calendar_view.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/events_feed_widgets.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_filter_chips.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/events_filter_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  EventsFeedScreenState createState() => EventsFeedScreenState();
}

class EventsFeedScreenState extends State<EventsFeedScreen> {
  static const Duration _silentRefreshMinInterval = Duration(minutes: 3);

  late final EventsFeedController _feed = EventsFeedController(
    repository: EventsRepositoryRegistry.instance,
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _feed.addListener(_onFeedUpdate);
    _scrollController.addListener(_onScrollNearBottom);
    // [context.l10n] requires [Localizations]; inherited widgets are not available
    // during [initState] (see HomeShell IndexedStack child build order).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_feed.loadCalendarViewPreference());
      unawaited(
        _feed.loadInitial(
          initialListEmptyErrorMessage: context.l10n.eventsFeedInitialLoadFailed,
        ),
      );
    });
    unawaited(_feed.loadRecentSearches());
  }

  void _onFeedUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScrollNearBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition pos = _scrollController.position;
    if (!pos.hasViewportDimension || !pos.hasPixels) {
      return;
    }
    if (pos.pixels <= pos.maxScrollExtent - 480) {
      return;
    }
    if (!_feed.repository.hasMoreEvents) {
      return;
    }
    unawaited(_feed.repository.loadMore().catchError((Object _) {
      logEventsDiagnostic('events_feed_load_more_failed');
    }));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _feed.removeListener(_onFeedUpdate);
    _feed.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _feed.onSearchTextChanged(value);
  }

  Future<void> _openFilterSheet() async {
    AppHaptics.tap();
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await EventsFilterSheet.show(
      context,
      current: _feed.activeSearchParams,
    );
    if (result == null || !mounted) {
      return;
    }
    final bool ok = await _feed.setSearchParams(result);
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_refresh_failed');
      AppSnack.show(
        context,
        message: context.l10n.eventsFeedRefreshFailed,
        type: AppSnackType.warning,
      );
    }
  }

  void _onFilterChanged(EcoEventFilter filter) {
    AppHaptics.tap();
    unawaited(() async {
      final bool ok = await _feed.setActiveFilter(filter);
      if (!ok && mounted) {
        logEventsDiagnostic('events_feed_refresh_failed');
        AppSnack.show(
          context,
          message: context.l10n.eventsFeedRefreshFailed,
          type: AppSnackType.warning,
        );
      }
    }());
  }

  Future<void> _onRefresh() async {
    AppHaptics.medium();
    final bool ok = await _feed.userPullRefresh();
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_refresh_failed');
      AppSnack.show(
        context,
        message: context.l10n.eventsFeedRefreshFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _retryInitialLoad() async {
    await _feed.loadInitial(
      initialListEmptyErrorMessage: context.l10n.eventsFeedInitialLoadFailed,
    );
  }

  Future<void> _navigateToDetail(EcoEvent event) async {
    AppHaptics.softTransition();
    final String cover = event.siteImageUrl.trim();
    if (cover.isNotEmpty) {
      final String lower = cover.toLowerCase();
      if (lower.startsWith('http://') || lower.startsWith('https://')) {
        await precacheImage(NetworkImage(cover), context);
      }
    }
    if (!mounted) {
      return;
    }
    await EventsNavigation.openDetail(context, eventId: event.id);
  }

  Future<void> _navigateToCreate() async {
    AppHaptics.softTransition();
    final EcoEvent? createdEvent = await EventsNavigation.openCreate(context);
    if (!mounted || createdEvent == null) {
      return;
    }
    await EventsNavigation.openDetail(context, eventId: createdEvent.id);
  }

  Future<void> _resetFiltersAndRefresh() async {
    AppHaptics.tap();
    final bool ok = await _feed.resetAllDiscoveryFilters();
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_refresh_failed');
      AppSnack.show(
        context,
        message: context.l10n.eventsFeedRefreshFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _clearSearchOnly() async {
    AppHaptics.tap();
    final bool ok = await _feed.clearSearchField();
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_refresh_failed');
      AppSnack.show(
        context,
        message: context.l10n.eventsFeedRefreshFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> scrollToTop() async {
    if (!_scrollController.hasClients) {
      return;
    }
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.standard;
    await _scrollController.animateTo(
      0,
      duration: duration,
      curve: AppMotion.emphasized,
    );
  }

  /// When the Events tab becomes active and the list is older than [_silentRefreshMinInterval].
  Future<void> silentRefreshIfStale() async {
    final DateTime? last = _feed.repository.lastSuccessfulListRefreshAt;
    if (last == null) {
      return;
    }
    if (DateTime.now().difference(last) < _silentRefreshMinInterval) {
      return;
    }
    final bool ok = await _feed.userPullRefresh();
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_silent_refresh_failed');
    }
  }

  Future<void> _onRecentSearchTap(String s) async {
    AppHaptics.light();
    final bool ok = await _feed.applySearchSuggestion(s);
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_refresh_failed');
      AppSnack.show(
        context,
        message: context.l10n.eventsFeedRefreshFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _calendarLoadMore() async {
    try {
      await _feed.repository.loadMore();
    } on Object catch (_) {
      if (mounted) {
        logEventsDiagnostic('events_calendar_load_more_failed');
        AppSnack.show(
          context,
          message: context.l10n.eventsFeedRefreshFailed,
          type: AppSnackType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<EcoEvent> filtered = _feed.filteredEvents(context.l10n);
    final EcoEvent? hero = _feed.heroEvent;
    final bool showSections =
        _feed.activeFilter == EcoEventFilter.all && _feed.searchQuery.isEmpty;
    final bool showHero = hero != null && showSections && !_feed.calendarView;
    final EcoEvent? featuredHeroForList = showHero ? hero : null;
    final List<EcoEvent> happeningNowRows = featuredHeroForList != null
        ? _feed.happeningNow
            .where((EcoEvent e) => e.id != featuredHeroForList.id)
            .toList()
        : _feed.happeningNow;
    final List<EcoEvent> comingUpRows = _feed.comingUp
        .where((EcoEvent e) => hero == null || e.id != hero.id)
        .toList();

    final List<EcoEvent> listToShow = showHero
        ? filtered.where((EcoEvent e) => e.id != hero.id).toList()
        : filtered;

    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isOrganizer =
        _feed.events.any((EcoEvent e) => e.isOrganizer);
    final String phase = _feed.feedPhase();

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Semantics(
          label: context.l10n.eventsFeedSemantic,
          child: RefreshIndicator(
            color: AppColors.primary,
            displacement: 48,
            strokeWidth: 2.2,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: <Widget>[
                // Same pattern as [ReportsListScreen]: static headline + tools (no collapsing app bar).
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            context.l10n.eventsFeedTitle,
                            style: AppTypography.eventsFeedScreenTitle(
                              Theme.of(context).textTheme,
                            ),
                          ),
                        ),
                        if (isOrganizer)
                          Semantics(
                            button: true,
                            label: context.l10n.eventsOrganizerDashboardTitle,
                            child: Material(
                              color: AppColors.transparent,
                              child: InkWell(
                                onTap: () => EventsNavigation.openOrganizerDashboard(
                                  context,
                                ),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 44,
                                  height: AppSpacing.avatarMd,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.chart_bar_alt_fill,
                                    size: 18,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (isOrganizer) const SizedBox(width: 4),
                        Semantics(
                          button: true,
                          label: context.l10n.eventsFeedCreateSemantic,
                          child: Material(
                            color: AppColors.transparent,
                            child: InkWell(
                              onTap: _navigateToCreate,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 44,
                                height: AppSpacing.avatarMd,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.add,
                                  size: 22,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
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
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: CupertinoSearchTextField(
                          controller: _feed.searchController,
                          placeholder: context.l10n.eventsFeedSearchPlaceholder,
                          style: AppTypography.eventsSearchFieldText(
                            Theme.of(context).textTheme,
                          ),
                          placeholderStyle: AppTypography.eventsSearchFieldPlaceholder(
                            Theme.of(context).textTheme,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.radius10,
                          ),
                          backgroundColor: AppColors.panelBackground,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          onChanged: _onSearchChanged,
                          onSubmitted: _feed.rememberSearch,
                          onSuffixTap: () {
                            AppHaptics.tap();
                            unawaited(() async {
                              final bool ok = await _feed.clearSearchField();
                              if (!ok && context.mounted) {
                                logEventsDiagnostic('events_feed_refresh_failed');
                                AppSnack.show(
                                  context,
                                  message:
                                      context.l10n.eventsFeedRefreshFailed,
                                  type: AppSnackType.warning,
                                );
                              }
                            }());
                          },
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
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _feed.hasActiveFilters
                                    ? AppColors.primary.withValues(alpha: 0.14)
                                    : AppColors.panelBackground,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: _feed.hasActiveFilters
                                      ? AppColors.primary
                                          .withValues(alpha: 0.4)
                                      : AppColors.divider
                                          .withValues(alpha: 0.6),
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
                                        ? AppColors.primaryDark
                                        : AppColors.textSecondary,
                                  ),
                                  if (_feed.hasActiveFilters)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryDark,
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
                          AppHaptics.tap();
                          _feed.setCalendarView(false);
                        },
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        icon: CupertinoIcons.calendar,
                        selected: _feed.calendarView,
                        tooltip: context.l10n.eventsFeedViewCalendarToggle,
                        onTap: () {
                          AppHaptics.tap();
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

              if (phase == 'content' &&
                  _feed.repository.isShowingStaleCachedEvents)
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
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                CupertinoIcons.wifi_slash,
                                size: 20,
                                color: AppColors.primaryDark,
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

              if (phase != 'content') ...<Widget>[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AnimatedPhaseSwitcher(
                    phaseKey: phase,
                    child: phase == 'loading'
                        ? const SingleChildScrollView(
                            padding: EdgeInsets.only(top: AppSpacing.md),
                            child: EventsFeedSkeleton(),
                          )
                        : AppErrorView(
                            error: _feed.initialLoadError!,
                            onRetry: _retryInitialLoad,
                          ),
                  ),
                ),
              ] else ...<Widget>[
                if (showHero)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
                      ),
                      child: HeroEventCard(
                        event: hero,
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
                      startIndex: 0,
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg)),
                  ],
                  if (comingUpRows.isNotEmpty) ...<Widget>[
                    SectionHeader(title: context.l10n.eventsFeedComingUp),
                    EventsSliverList(
                      events: comingUpRows,
                      onTap: _navigateToDetail,
                      startIndex: happeningNowRows.length,
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg)),
                  ],
                  if (_feed.recentlyCompleted.isNotEmpty) ...<Widget>[
                    SectionHeader(
                        title: context.l10n.eventsFeedRecentlyCompleted),
                    EventsSliverList(
                      events: _feed.recentlyCompleted.take(3).toList(),
                      onTap: _navigateToDetail,
                      startIndex:
                          happeningNowRows.length + comingUpRows.length,
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
                        onClearFilters:
                            _feed.hasActiveFilters ? _resetFiltersAndRefresh : null,
                        onCreateEvent: _navigateToCreate,
                      ),
                    ),
                ]
                else if (!showSections && !_feed.calendarView) ...<Widget>[
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
                child: SizedBox(
                  height: AppSpacing.xxl + keyboardInset,
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
