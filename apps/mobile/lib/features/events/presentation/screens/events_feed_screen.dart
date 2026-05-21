library;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/providers/events_providers.dart';
import 'package:chisto_mobile/core/providers/home_providers.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_cupertino_search_field.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/features/events/data/api_events_repository.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/controllers/events_feed_controller.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_scroll_interaction.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_calendar_view.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/events_feed_widgets.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_filter_chips.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/events_filter_sheet.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:chisto_mobile/features/events/presentation/providers/events_feed_controller_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


part '../widgets/events_feed/events_feed_toolbar.dart';
part '../widgets/events_feed/events_feed_content_slivers.dart';

class EventsFeedScreen extends ConsumerStatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  EventsFeedScreenState createState() => EventsFeedScreenState();
}

class EventsFeedScreenState extends ConsumerState<EventsFeedScreen> {
  static const Duration _silentRefreshMinInterval = Duration(minutes: 3);

  EventsFeedController? _boundFeed;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _lastCoverPrecacheSignature;

  EventsFeedController get _feed {
    final EventsFeedController? bound = _boundFeed;
    assert(bound != null, 'Events feed controller not bound yet');
    return bound!;
  }

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
    _scrollController.addListener(_onScrollNearBottom);
  }

  /// Keeps the screen on the live Riverpod instance (hot restart / provider recreate).
  void _bindFeedController(EventsFeedController feed) {
    if (identical(_boundFeed, feed)) {
      return;
    }
    _boundFeed?.removeListener(_onFeedUpdate);
    _boundFeed = feed;
    feed.addListener(_onFeedUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapFeed(feed));
  }

  void _bootstrapFeed(EventsFeedController feed) {
    if (!mounted || !identical(_boundFeed, feed)) {
      return;
    }
    unawaited(_refreshUserLocationHints());
    unawaited(feed.loadCalendarViewPreference());
    unawaited(feed.loadRecentSearches());
    if (feed.feedPhase() == 'loading') {
      unawaited(
        feed.loadInitial(
          initialListEmptyErrorMessage:
              context.l10n.eventsFeedInitialLoadFailed,
        ),
      );
    }
  }

  void _onFeedUpdate() {
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
    final LocationService geo = ref.read(locationServiceProvider);
    try {
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
      if (!mounted) return;
      _feed.setUserLocationHint(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (!mounted) return;
      final Object repository = EventsRepositoryRegistry.instance;
      if (repository is ApiEventsRepository) {
        repository.setUserLocationHint(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    } on Exception catch (_) {
      // Keep existing recommendation state when location hint cannot be refreshed.
    }
  }

  /// Warms the image cache for the first visible-ish HTTPS thumbnails (decode budget).
  void _precacheEventCoverThumbnails(
    BuildContext context,
    List<EcoEvent> events,
  ) {
    if (!context.mounted) {
      return;
    }
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    const int logicalThumbPx = 88;
    final int dim = (logicalThumbPx * dpr).round().clamp(64, 768);
    int budget = 0;
    for (final EcoEvent e in events) {
      if (budget >= 14) {
        break;
      }
      final String raw = e.siteImageUrl.trim();
      if (raw.isEmpty || !EcoEventCoverImage.isNetworkUrl(raw)) {
        continue;
      }
      budget++;
      final ImageProvider<Object> provider = ResizeImage(
        NetworkImage(raw),
        width: dim,
        height: dim,
      );
      unawaited(precacheImage(provider, context).catchError((Object _) {}));
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
    unawaited(
      _feed.repository.loadMore().catchError((Object _) {
        logEventsDiagnostic('events_feed_load_more_failed');
      }),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollNearBottom);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _boundFeed?.removeListener(_onFeedUpdate);
    _boundFeed?.remoteSearch.cancel();
    _boundFeed = null;
    // EventsFeedController lifecycle is owned by eventsFeedControllerProvider.
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
      final String message = err != null
          ? localizedAppErrorMessage(context.l10n, err)
          : context.l10n.eventsFeedRefreshFailed;
      AppSnack.show(context, message: message, type: AppSnackType.warning);
    }
  }

  Future<void> _retryInitialLoad() async {
    await _feed.loadInitial(
      initialListEmptyErrorMessage: context.l10n.eventsFeedInitialLoadFailed,
    );
  }

  Future<void> _navigateToDetail(EcoEvent event) async {
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
    final EcoEvent? createdEvent = await EventsNavigation.openCreate(context);
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
    final EventsFeedController feed = ref.watch(eventsFeedControllerProvider);
    _bindFeedController(feed);
    final double bottomSafePadding = MediaQuery.paddingOf(context).bottom;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      // Inset applied by tab [HomeShell] to avoid double layout on iOS.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: feed,
          builder: (BuildContext context, Widget? _) {
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

            return Semantics(
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
                  ),
                ],
              );
              return AppRefreshIndicator(
                onRefresh: _onRefresh,
                child: scrollView,
              );
            },
          ),
        );
          },
        ),
      ),
    );
  }
}
