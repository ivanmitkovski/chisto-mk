import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/events_discovery_preferences.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/eco_event_card.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_card_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_calendar_view.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_filter_chips.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/animated_list_item.dart';

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
  String _searchQuery = '';
  bool _calendarView = false;
  List<String> _recentSearches = const <String>[];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _eventsStore.loadInitialIfNeeded();
    _eventsStore.addListener(_onEventsUpdated);
    _allEvents = _eventsStore.events;
    _loadDiscoveryPreferences();
    Future<void>.delayed(AppMotion.slow, () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
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
    await Future<void>.delayed(AppMotion.slow);
    if (!mounted) return;
    setState(() => _allEvents = _eventsStore.events);
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

    return Scaffold(
      backgroundColor: AppColors.appBackground,
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
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _navigateToCreate,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 44,
                              height: 44,
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
                          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                          placeholderStyle: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          backgroundColor: AppColors.panelBackground,
                          borderRadius: BorderRadius.circular(12),
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
                      _ViewToggleButton(
                        icon: CupertinoIcons.square_list_fill,
                        selected: !_calendarView,
                        onTap: () {
                          AppHaptics.tap();
                          setState(() => _calendarView = false);
                        },
                      ),
                      const SizedBox(width: 4),
                      _ViewToggleButton(
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
                  child: _RecentSearchesShelf(
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

              // ── Hero card ("Up Next") ──
              if (showHero)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
                    ),
                    child: _HeroEventCard(
                      event: hero,
                      onTap: () => _navigateToDetail(hero),
                    ),
                  ),
                ),

              // ── Sections for "All" filter ──
              if (showSections && !_calendarView && !_isLoading) ...<Widget>[
                if (_happeningNow.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'Happening now'),
                  _EventsSliverList(
                    events: _happeningNow,
                    onTap: _navigateToDetail,
                    startIndex: 0,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                ],
                if (_comingUp.where((EcoEvent e) => hero == null || e.id != hero.id).isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'Coming up'),
                  _EventsSliverList(
                    events: _comingUp.where((EcoEvent e) => hero == null || e.id != hero.id).toList(),
                    onTap: _navigateToDetail,
                    startIndex: _happeningNow.length,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                ],
                if (_recentlyCompleted.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'Recently completed'),
                  _EventsSliverList(
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
                    child: _EmptyState(filter: _activeFilter),
                  ),
              ]
              // ── Non-sectioned list or calendar ──
              else if (!showSections && !_calendarView && !_isLoading) ...<Widget>[
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _searchQuery.isNotEmpty
                        ? _SearchEmptyState(query: _searchQuery)
                        : _EmptyState(filter: _activeFilter),
                  )
                else
                  _EventsSliverList(
                    events: listToShow,
                    onTap: _navigateToDetail,
                  ),
              ],

              // ── Calendar view ──
              if (_calendarView && !_isLoading)
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

              // ── Loading skeletons ──
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, __) => const EventCardSkeleton(),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero "Up Next" card
// ---------------------------------------------------------------------------

class _HeroEventCard extends StatelessWidget {
  const _HeroEventCard({required this.event, required this.onTap});

  final EcoEvent event;
  final VoidCallback onTap;

  String get _countdownLabel {
    final Duration diff = event.startDateTime.difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    if (diff.inDays > 0) return 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'Starts in ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.emphasized,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              // Background image
              Hero(
                tag: 'event-thumb-${event.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Image.asset(
                      event.siteImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const <double>[0.3, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _countdownLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(CupertinoIcons.location_solid, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.siteName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.formattedTimeRange,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Top-right "Up Next" label
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Up next',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm,
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Events sliver list with stagger
// ---------------------------------------------------------------------------

class _EventsSliverList extends StatelessWidget {
  const _EventsSliverList({
    required this.events,
    required this.onTap,
    this.startIndex = 0,
  });

  final List<EcoEvent> events;
  final ValueChanged<EcoEvent> onTap;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList.separated(
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final EcoEvent event = events[index];
          return AnimatedListItem(
            index: startIndex + index,
            child: EcoEventCard(
              event: event,
              onTap: () => onTap(event),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View toggle button
// ---------------------------------------------------------------------------

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.panelBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primaryDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery shelf (recent searches)
// ---------------------------------------------------------------------------

class _RecentSearchesShelf extends StatelessWidget {
  const _RecentSearchesShelf({
    required this.recentSearches,
    required this.onSearchTap,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onSearchTap;

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Recent searches',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentSearches.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) {
                final String query = recentSearches[index];
                return ActionChip(
                  avatar: const Icon(
                    CupertinoIcons.time,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  label: Text(query),
                  onPressed: () => onSearchTap(query),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final EcoEventFilter filter;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;
    final IconData icon;
    switch (filter) {
      case EcoEventFilter.all:
        title = 'No eco events yet';
        subtitle = 'Be the first to create one! Tap + above to get started.';
        icon = CupertinoIcons.calendar_badge_plus;
      case EcoEventFilter.upcoming:
        title = 'No upcoming events';
        subtitle = 'Create one to get volunteers together.';
        icon = CupertinoIcons.clock;
      case EcoEventFilter.nearby:
        title = 'No nearby events';
        subtitle = 'Try a different filter or create an event in your area.';
        icon = CupertinoIcons.location;
      case EcoEventFilter.past:
        title = 'No past events';
        subtitle = 'Completed events will show here.';
        icon = CupertinoIcons.checkmark_circle;
      case EcoEventFilter.myEvents:
        title = 'No events yet';
        subtitle = 'Join or create an event to see it here.';
        icon = CupertinoIcons.person_crop_circle;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: AppMotion.slow,
            curve: AppMotion.emphasized,
            builder: (_, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search-specific empty state
// ---------------------------------------------------------------------------

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.search,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No results for "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Try a different search term or check your spelling.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
