library;

import 'dart:async';

import 'package:chisto_infrastructure/core/auth/session_invalidation.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/api_events_repository.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/controllers/events_feed_controller.dart';
import 'package:feature_events/src/presentation/controllers/events_search_controller.dart';
import 'package:feature_events/src/presentation/navigation/events_navigation.dart';
import 'package:feature_events/src/presentation/utils/events_diagnostic_log.dart';
import 'package:feature_events/src/presentation/utils/events_scroll_interaction.dart';
import 'package:chisto_infrastructure/core/navigation/event_detail_navigation_guard.dart';
import 'package:chisto_infrastructure/core/cache/report_image_provider.dart';
import 'package:chisto_infrastructure/core/cache/site_image_prefetch_queue.dart';
import 'package:chisto_infrastructure/core/cache/site_image_provider.dart';
import 'package:feature_events/src/presentation/widgets/events_calendar_view.dart';
import 'package:feature_events/src/presentation/widgets/events_feed/events_feed_widgets.dart';
import 'package:feature_events/src/presentation/widgets/events_feed/events_filter_sheet.dart';
import 'package:feature_events/src/presentation/widgets/events_feed_skeleton.dart';
import 'package:feature_events/src/presentation/widgets/events_filter_chips.dart';
import 'package:feature_events/src/presentation/controllers/events_feed_state.dart';
import 'package:feature_home/feature_home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

part '../widgets/events_feed/events_feed_content_slivers.dart';
part '../widgets/events_feed/events_feed_toolbar.dart';

class EventsFeedScreen extends ConsumerStatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  EventsFeedScreenState createState() => EventsFeedScreenState();
}

class EventsFeedScreenState extends ConsumerState<EventsFeedScreen> {
  static const Duration _silentRefreshMinInterval = Duration(minutes: 3);

  Object? _bootstrappedFeedIdentity;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _lastCoverPrecacheSignature;
  late final EventsSearchController _searchController;

  EventsFeedController get _feed =>
      ref.read(eventsFeedControllerProvider.notifier);

  void _onRemoteRefreshTick() {
    if (!mounted) {
      return;
    }
    unawaited(
      _feed.refreshMergedList().catchError((Object _) {
        logEventsDiagnostic('events_feed_remote_refresh_failed');
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController = ref.read(eventsSearchControllerProvider.notifier);
    _scrollController.addListener(_onScrollNearBottom);
  }

  /// Runs once per Riverpod feed instance (hot restart / provider recreate).
  void _ensureFeedBootstrapped(EventsFeedController feed) {
    final Object identity = feed;
    if (identical(_bootstrappedFeedIdentity, identity)) {
      return;
    }
    _bootstrappedFeedIdentity = identity;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapFeed(feed));
  }

  void _bootstrapFeed(EventsFeedController feed) {
    if (!mounted || !identical(_bootstrappedFeedIdentity, feed)) {
      return;
    }
    unawaited(_bootstrapFeedAsync(feed));
  }

  Future<void> _bootstrapFeedAsync(EventsFeedController feed) async {
    if (!mounted || !identical(_bootstrappedFeedIdentity, feed)) {
      return;
    }
    await _refreshUserLocationHints();
    if (!mounted || !identical(_bootstrappedFeedIdentity, feed)) {
      return;
    }
    unawaited(feed.loadCalendarViewPreference());
    unawaited(feed.loadRecentSearches());
    if (feed.feedPhase() == 'loading') {
      if (!mounted) {
        return;
      }
      final String initialLoadFailedMessage =
          context.l10n.eventsFeedInitialLoadFailed;
      await feed.loadInitial(
        initialListEmptyErrorMessage: initialLoadFailedMessage,
      );
    }
  }

  void _maybePrecacheCovers() {
    if (!mounted) {
      return;
    }
    if (_feed.feedPhase() != 'content') {
      return;
    }
    final List<EcoEvent> events = _feed.events;
    if (events.isEmpty) {
      return;
    }
    final String signature =
        '${events.length}|${events.first.id}|${events.last.id}|${_feed.heroEvent?.id ?? ''}';
    if (signature == _lastCoverPrecacheSignature) {
      return;
    }
    _lastCoverPrecacheSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _precacheEventCoverThumbnails(context, events);
    });
  }

  Future<void> _refreshUserLocationHints() async {
    double? lat;
    double? lng;

    try {
      final LatLng? tracked = ref.read(
        mapLocationNotifierProvider.select(
          (MapLocationState state) => state.userLocation,
        ),
      );
      if (tracked != null) {
        lat = tracked.latitude;
        lng = tracked.longitude;
      }

      if (lat == null || lng == null) {
        final LocationService geo = ref.read(locationServiceProvider);
        if (!await geo.isLocationServiceEnabled()) {
          return;
        }
        AppLocationPermission permission = await geo.checkPermission();
        if (permission == AppLocationPermission.denied) {
          permission = await geo.requestPermission();
        }
        if (permission != AppLocationPermission.whileInUse &&
            permission != AppLocationPermission.always) {
          return;
        }
        final GeoPosition pos = await geo.getCurrentPosition(
          accuracy: AppGeoAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      }

      if (lat == null || lng == null || !mounted) {
        return;
      }
      _feed.setUserLocationHint(latitude: lat, longitude: lng);
      if (!mounted) return;
      final Object repository = readEventsRepository();
      if (repository is ApiEventsRepository) {
        repository.setUserLocationHint(latitude: lat, longitude: lng);
      }
    } on Exception catch (_) {
      // Keep existing recommendation state when location hint cannot be refreshed.
    }
  }

  /// Warms the disk + memory cache for the first visible HTTPS thumbnails.
  void _precacheEventCoverThumbnails(
    BuildContext context,
    List<EcoEvent> events,
  ) {
    if (!context.mounted) {
      return;
    }
    final List<ImageProvider<Object>> providers = <ImageProvider<Object>>[];
    for (final EcoEvent e in events) {
      if (providers.length >= 14) {
        break;
      }
      final String raw = e.siteImageUrl.trim();
      if (raw.isEmpty ||
          !(raw.toLowerCase().startsWith('http://') ||
              raw.toLowerCase().startsWith('https://'))) {
        continue;
      }
      providers.add(imageProviderForEventFeedCover(raw));
    }
    SiteImagePrefetchQueue.instance.prefetchList(
      context,
      providers,
      maxItems: providers.length,
    );
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
    unawaited(() async {
      try {
        await _feed.repository.loadMore();
      } on Object catch (_) {
        logEventsDiagnostic('events_feed_load_more_failed');
        if (mounted) {
          AppSnack.show(
            context,
            message: context.l10n.eventsFeedRefreshFailed,
            type: AppSnackType.warning,
          );
        }
      }
    }());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollNearBottom);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _feed.onSearchTextChanged(value);
  }

  Future<void> _openFilterSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await EventsFilterSheet.show(
      context,
      current: _feed.activeSearchParams,
      activeChip: _feed.activeFilter,
      repository: _feed.repository,
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
    eventsPullRefreshHaptic(context);
    await _refreshUserLocationHints();
    final bool ok = await _feed.userPullRefresh();
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_refresh_failed');
      final AppError? err = _feed.lastPullRefreshError;
      if (err != null && SessionInvalidation.shouldHandle(err)) {
        unawaited(SessionInvalidation.fromError(err));
        return;
      }
      final String message = err != null
          ? localizedAppErrorMessage(context.l10n, err)
          : context.l10n.eventsFeedRefreshFailed;
      AppSnack.show(context, message: message, type: AppSnackType.warning);
    }
  }

  Future<void> _retryInitialLoad() async {
    final String emptyMessage = context.l10n.eventsFeedInitialLoadFailed;
    await _feed.loadInitial(initialListEmptyErrorMessage: emptyMessage);
  }

  Future<void> _navigateToDetail(EcoEvent event) async {
    if (EventDetailNavigationGuard.isEventDetailTopRoute(event.id)) {
      return;
    }
    final String cover = event.siteImageUrl.trim();
    if (cover.isNotEmpty) {
      final String lower = cover.toLowerCase();
      if (lower.startsWith('http://') || lower.startsWith('https://')) {
        final ImageProvider<Object> provider = lower.contains('/reports/')
            ? imageProviderForReportEvidence(
                cover,
                maxWidth: kEventFeedCoverDecodeMaxPx,
                maxHeight: kEventFeedCoverDecodeMaxPx,
              )
            : imageProviderForEventFeedCover(cover);
        await safePrecacheImage(provider, context);
      }
    }
    if (!mounted) {
      return;
    }
    await EventsNavigation.openDetail(context, eventId: event.id);
  }

  Future<void> _navigateToCreate() async {
    final EcoEvent? createdEvent = await EventsNavigation.openCreate(
      context,
      ref: ref,
      auth: ref.read(authStateProvider),
    );
    if (!mounted || createdEvent == null) {
      return;
    }
    await EventsNavigation.openDetail(context, eventId: createdEvent.id);
  }

  Future<void> _resetFiltersAndRefresh() async {
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
    await _refreshUserLocationHints();
    final bool ok = await _feed.userPullRefresh();
    if (!ok && mounted) {
      logEventsDiagnostic('events_feed_silent_refresh_failed');
      final AppError? err = _feed.lastPullRefreshError;
      if (err != null && SessionInvalidation.shouldHandle(err)) {
        unawaited(SessionInvalidation.fromError(err));
        return;
      }
      final String message = err != null
          ? localizedAppErrorMessage(context.l10n, err)
          : context.l10n.eventsFeedRefreshFailed;
      AppSnack.show(context, message: message, type: AppSnackType.warning);
    }
  }

  Future<void> _onRecentSearchTap(String s) async {
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
    ref.listen<int>(eventsFeedRefreshTickProvider, (int? previous, int next) {
      if (previous != next) {
        _onRemoteRefreshTick();
      }
    });
    ref.listen(eventsFeedControllerProvider, (Object? previous, Object next) {
      _maybePrecacheCovers();
    });
    ref.watch(eventsSearchControllerProvider);
    final EventsFeedState feedState = ref.watch(eventsFeedControllerProvider);
    final EventsFeedController feed = ref.read(
      eventsFeedControllerProvider.notifier,
    );
    _ensureFeedBootstrapped(feed);
    final double bottomSafePadding = MediaQuery.paddingOf(context).bottom;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

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

    final bool isOrganizer = _feed.events.any((EcoEvent e) => e.isOrganizer);
    final String phase = _feed.feedPhase();

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      // Inset applied by tab [HomeShell] to avoid double layout on iOS.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Semantics(
          label: context.l10n.eventsFeedSemantic,
          child: Builder(
            builder: (BuildContext context) {
              if (phase == 'loading') {
                final Widget loadingScroll = CustomScrollView(
                  controller: _scrollController,
                  physics: eventsListScrollPhysics(context),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: EventsFeedSkeleton(
                        calendarView: _feed.calendarView,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: AppSpacing.xxl + bottomSafePadding,
                      ),
                    ),
                  ],
                );
                return AppRefreshIndicator(
                  onRefresh: _onRefresh,
                  child: loadingScroll,
                );
              }

              final Widget scrollView = CustomScrollView(
                controller: _scrollController,
                physics: eventsListScrollPhysics(context),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                  ...buildEventsFeedToolbarSlivers(
                    context: context,
                    colorScheme: colorScheme,
                    bottomSafePadding: bottomSafePadding,
                    filtered: filtered,
                    hero: hero,
                    showSections: showSections,
                    showHero: showHero,
                    featuredHeroForList: featuredHeroForList,
                    happeningNowRows: happeningNowRows,
                    comingUpRows: comingUpRows,
                    listToShow: listToShow,
                    isOrganizer: isOrganizer,
                    phase: phase,
                  ),
                  ...buildEventsFeedContentSlivers(
                    context: context,
                    colorScheme: colorScheme,
                    bottomSafePadding: bottomSafePadding,
                    filtered: filtered,
                    hero: hero,
                    showSections: showSections,
                    showHero: showHero,
                    featuredHeroForList: featuredHeroForList,
                    happeningNowRows: happeningNowRows,
                    comingUpRows: comingUpRows,
                    listToShow: listToShow,
                    isOrganizer: isOrganizer,
                    phase: phase,
                    userLatitude: feedState.userLatitude,
                    userLongitude: feedState.userLongitude,
                  ),
                ],
              );
              return AppRefreshIndicator(
                onRefresh: _onRefresh,
                child: scrollView,
              );
            },
          ),
        ),
      ),
    );
  }
}
