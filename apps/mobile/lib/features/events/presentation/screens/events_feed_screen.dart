import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/events_discovery_preferences.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_card_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_calendar_view.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/events_feed_widgets.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_filter_chips.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  State<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends State<EventsFeedScreen> {
  final EventsRepository _eventsStore = EventsRepositoryRegistry.instance;
  final EventsDiscoveryPreferences _discoveryPreferences =
      const EventsDiscoveryPreferences();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late List<EcoEvent> _allEvents;
  EcoEventFilter _activeFilter = EcoEventFilter.all;
  bool _isLoading = true;
  AppError? _loadError;
  String _searchQuery = '';
  bool _calendarView = false;
  List<String> _recentSearches = const <String>[];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _eventsStore.addListener(_onEventsUpdated);
    _allEvents = _eventsStore.events;
    _loadDiscoveryPreferences();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    try {
      await Future<void>.delayed(AppMotion.slow);
      if (!mounted) return;
      _eventsStore.loadInitialIfNeeded();
      setState(() {
        _allEvents = _eventsStore.events;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = AppError.network(cause: e);
        _isLoading = false;
      });
      if (mounted) {
        AppSnack.show(
          context,
          message: 'No connection',
          type: AppSnackType.warning,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _eventsStore.removeListener(_onEventsUpdated);
    super.dispose();
  }

  void _onEventsUpdated() {
    if (!mounted) return;
    void applyUpdate() {
      if (!mounted) return;
      setState(() => _allEvents = _eventsStore.events);
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
      return;
    }
    applyUpdate();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  Future<void> _loadDiscoveryPreferences() async {
    final List<String> recent = await _discoveryPreferences.readRecentSearches();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches = recent;
    });
  }

  Future<void> _rememberSearch(String value) async {
    final String q = value.trim();
    if (q.length < 2) {
      return;
    }
    final List<String> next = <String>[
      q,
      ..._recentSearches.where(
        (String existing) => existing.toLowerCase() != q.toLowerCase(),
      ),
    ];
    await _discoveryPreferences.writeRecentSearches(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentSearches = next.take(8).toList(growable: false);
    });
  }

  void _applySearchSuggestion(String suggestion) {
    AppHaptics.light();
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    _debounce?.cancel();
    setState(() {
      _searchQuery = suggestion;
    });
    _rememberSearch(suggestion);
  }

  // ── Section builders ──────────────────────────────────────

  List<EcoEvent> get _happeningNow => _allEvents
      .where((EcoEvent e) => e.status == EcoEventStatus.inProgress)
      .toList();

  List<EcoEvent> get _comingUp => _applyDiscoverySort(
        _allEvents.where((EcoEvent e) => e.status == EcoEventStatus.upcoming).toList(),
      );

  List<EcoEvent> get _recentlyCompleted => _allEvents
      .where((EcoEvent e) =>
          e.status == EcoEventStatus.completed || e.status == EcoEventStatus.cancelled)
      .toList()
    ..sort((EcoEvent a, EcoEvent b) => b.date.compareTo(a.date));

  EcoEvent? get _heroEvent {
    final List<EcoEvent> upcoming = _comingUp;
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  List<EcoEvent> get _filteredEvents {
    List<EcoEvent> list;
    switch (_activeFilter) {
      case EcoEventFilter.all:
        list = _applyDiscoverySort(_allEvents);
      case EcoEventFilter.upcoming:
        list = _applyDiscoverySort(
          _allEvents.where((EcoEvent e) => e.status == EcoEventStatus.upcoming).toList(),
        );
      case EcoEventFilter.nearby:
        list = List<EcoEvent>.from(_allEvents)
          ..sort((EcoEvent a, EcoEvent b) {
            final int dist = a.siteDistanceKm.compareTo(b.siteDistanceKm);
            if (dist != 0) return dist;
            return a.startDateTime.compareTo(b.startDateTime);
          });
      case EcoEventFilter.past:
        list = _allEvents
            .where((EcoEvent e) =>
                e.status == EcoEventStatus.completed || e.status == EcoEventStatus.cancelled)
            .toList();
      case EcoEventFilter.myEvents:
        list = _applyDiscoverySort(
          _allEvents.where((EcoEvent e) => e.isOrganizer || e.isJoined).toList(),
        );
    }
    if (_searchQuery.trim().isEmpty) return list;
    final String q = _searchQuery.trim().toLowerCase();
    return _applyDiscoverySort(
      list
          .where((EcoEvent e) =>
              e.title.toLowerCase().contains(q) ||
              e.siteName.toLowerCase().contains(q) ||
              e.category.label.toLowerCase().contains(q))
          .toList(),
    );
  }

  List<EcoEvent> _applyDiscoverySort(List<EcoEvent> source) {
    final List<EcoEvent> sorted = List<EcoEvent>.from(source);
    sorted.sort((EcoEvent a, EcoEvent b) {
      final int rankCompare = _statusRank(a).compareTo(_statusRank(b));
      if (rankCompare != 0) return rankCompare;
      if (a.status == EcoEventStatus.completed || a.status == EcoEventStatus.cancelled) {
        return b.date.compareTo(a.date);
      }
      final int timeCompare = a.startDateTime.compareTo(b.startDateTime);
      if (timeCompare != 0) return timeCompare;
      return a.siteDistanceKm.compareTo(b.siteDistanceKm);
    });
    return sorted;
  }

  int _statusRank(EcoEvent event) {
    switch (event.status) {
      case EcoEventStatus.inProgress:
        return 0;
      case EcoEventStatus.upcoming:
        return 1;
      case EcoEventStatus.completed:
        return 2;
      case EcoEventStatus.cancelled:
        return 3;
    }
  }

  void _onFilterChanged(EcoEventFilter filter) {
    AppHaptics.tap();
    setState(() => _activeFilter = filter);
  }

  Future<void> _onRefresh() async {
    AppHaptics.medium();
    await _loadEvents();
  }

  Future<void> _navigateToDetail(EcoEvent event) async {
    AppHaptics.softTransition();
    await EventsNavigation.openDetail(context, eventId: event.id);
  }

  Future<void> _navigateToCreate() async {
    AppHaptics.softTransition();
    final EcoEvent? createdEvent = await EventsNavigation.openCreate(context);
    if (!mounted || createdEvent == null) return;
    await EventsNavigation.openDetail(context, eventId: createdEvent.id);
  }

  Future<void> scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: AppMotion.standard,
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final List<EcoEvent> filtered = _filteredEvents;
    final EcoEvent? hero = _heroEvent;
    final bool showSections = _activeFilter == EcoEventFilter.all && _searchQuery.isEmpty;
    final bool showHero = hero != null && showSections && !_calendarView;

    final List<EcoEvent> listToShow = showHero
        ? filtered.where((EcoEvent e) => e.id != hero.id).toList()
        : filtered;

    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: true,
      body: Semantics(
        label: 'Events feed',
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
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, topPadding + AppSpacing.lg,
                    AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Events',
                          style: AppTypography.textTheme.headlineLarge?.copyWith(
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Create event',
                        child: Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: _navigateToCreate,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 44,
                              height: AppSpacing.avatarMd,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
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

              // ── Search + view toggle ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: CupertinoSearchTextField(
                          controller: _searchController,
                          placeholder: 'Search events',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          placeholderStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.radius10,
                          ),
                          backgroundColor: AppColors.panelBackground,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          onChanged: _onSearchChanged,
                          onSubmitted: _rememberSearch,
                          onSuffixTap: () {
                            AppHaptics.tap();
                            _searchController.clear();
                            _debounce?.cancel();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ViewToggleButton(
                        icon: CupertinoIcons.square_list_fill,
                        selected: !_calendarView,
                        onTap: () {
                          AppHaptics.tap();
                          setState(() => _calendarView = false);
                        },
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        icon: CupertinoIcons.calendar,
                        selected: _calendarView,
                        onTap: () {
                          AppHaptics.tap();
                          setState(() => _calendarView = true);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (!_calendarView && _searchQuery.trim().isEmpty)
                SliverToBoxAdapter(
                  child: RecentSearchesShelf(
                    recentSearches: _recentSearches,
                    onSearchTap: _applySearchSuggestion,
                  ),
                ),

              // ── Filter chips ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: EventsFilterChips(
                    active: _activeFilter,
                    onSelected: _onFilterChanged,
                  ),
                ),
              ),

              if (_loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorView(
                    error: _loadError!,
                    onRetry: _loadEvents,
                  ),
                ),
              if (_loadError == null && showHero)
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

              if (_loadError == null && showSections && !_calendarView && !_isLoading) ...<Widget>[
                if (_happeningNow.isNotEmpty) ...<Widget>[
                  SectionHeader(title: 'Happening now'),
                  EventsSliverList(
                    events: _happeningNow,
                    onTap: _navigateToDetail,
                    startIndex: 0,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                ],
                if (_comingUp.where((EcoEvent e) => hero == null || e.id != hero.id).isNotEmpty) ...<Widget>[
                  SectionHeader(title: 'Coming up'),
                  EventsSliverList(
                    events: _comingUp.where((EcoEvent e) => hero == null || e.id != hero.id).toList(),
                    onTap: _navigateToDetail,
                    startIndex: _happeningNow.length,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                ],
                if (_recentlyCompleted.isNotEmpty) ...<Widget>[
                  SectionHeader(title: 'Recently completed'),
                  EventsSliverList(
                    events: _recentlyCompleted.take(3).toList(),
                    onTap: _navigateToDetail,
                    startIndex: _happeningNow.length + _comingUp.length,
                  ),
                ],
                if (_happeningNow.isEmpty &&
                    _comingUp.where((EcoEvent e) => hero == null || e.id != hero.id).isEmpty &&
                    _recentlyCompleted.isEmpty &&
                    hero == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EventsEmptyState(filter: _activeFilter),
                  ),
              ]
              else if (_loadError == null && !showSections && !_calendarView && !_isLoading) ...<Widget>[
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _searchQuery.isNotEmpty
                        ? SearchEmptyState(query: _searchQuery)
                        : EventsEmptyState(filter: _activeFilter),
                  )
                else
                  EventsSliverList(
                    events: listToShow,
                    onTap: _navigateToDetail,
                  ),
              ],

              if (_loadError == null && _calendarView && !_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
                    ),
                    child: EventsCalendarView(
                      events: filtered,
                      onEventTap: _navigateToDetail,
                    ),
                  ),
                ),

              if (_loadError == null && _isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, _) => const EventCardSkeleton(),
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: AppSpacing.xxl + keyboardInset,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
