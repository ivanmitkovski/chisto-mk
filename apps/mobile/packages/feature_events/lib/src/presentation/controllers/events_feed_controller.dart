import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/application/events_providers.dart';
import 'package:feature_events/src/data/events_discovery_preferences.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/controllers/events_feed_state.dart';
import 'package:feature_events/src/presentation/controllers/events_search_controller.dart';
import 'package:feature_events/src/presentation/utils/events_feed_search_merge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'events_feed_controller.g.dart';

/// Owns feed discovery state: debounced ranked search, chip/server params, calendar toggle,
/// and **memoized** derived lists (nearby / my-events client sorts only; text search is server-side).
@Riverpod(keepAlive: true)
class EventsFeedController extends _$EventsFeedController {
  late final EventsRepository _repository;
  late final EventsDiscoveryPreferences _discoveryPreferences;

  final TextEditingController searchController = TextEditingController();

  String? _derivedCacheKey;
  _EventsFeedDerived? _cachedDerived;

  Future<void>? _initialLoadFuture;
  bool _alive = true;

  @override
  EventsFeedState build() {
    _alive = true;
    _repository = ref.read(eventsRepositoryProvider);
    _discoveryPreferences = const EventsDiscoveryPreferences();

    void onRepositoryUpdate() {
      void applyUpdate() {
        if (!_alive) return;
        var next = state;
        if (events.isNotEmpty && next.initialLoadError != null) {
          next = next.copyWith(clearInitialLoadError: true);
        }
        _invalidateDerived();
        state = next.copyWith(repositoryEpoch: next.repositoryEpoch + 1);
      }

      if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
        WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
        return;
      }
      applyUpdate();
    }

    _repository.addListener(onRepositoryUpdate);
    final EventsSearchController search = ref.read(
      eventsSearchControllerProvider.notifier,
    );
    ref.onDispose(() {
      _alive = false;
      _repository.removeListener(onRepositoryUpdate);
      search.cancel();
      searchController.dispose();
    });

    return const EventsFeedState();
  }

  EventsRepository get repository => _repository;

  AppError? get lastPullRefreshError => state.lastPullRefreshError;

  bool get hasUserLocationHint =>
      state.userLatitude != null && state.userLongitude != null;

  EcoEventFilter get activeFilter => state.activeFilter;
  EcoEventSearchParams get activeSearchParams => state.activeSearchParams;

  List<String> get rankedSearchSuggestions =>
      _repository.lastRankedSearchSuggestions;
  String get searchQuery => state.searchQuery;
  bool get calendarView => state.calendarView;
  List<String> get recentSearches => state.recentSearches;
  bool get isInitialLoading => state.isInitialLoading;
  AppError? get initialLoadError => state.initialLoadError;

  List<EcoEvent> get events => _repository.events;

  bool get hasActiveFilters =>
      state.activeFilter != EcoEventFilter.all ||
      state.activeSearchParams.categories.isNotEmpty ||
      state.activeSearchParams.statuses.isNotEmpty ||
      state.activeSearchParams.dateFrom != null ||
      state.activeSearchParams.dateTo != null;

  /// `loading` / `error` / `content` — matches [EventsFeedScreen] phase switcher.
  String feedPhase() {
    if (state.isInitialLoading && events.isEmpty) {
      return 'loading';
    }
    if (state.initialLoadError != null && events.isEmpty) {
      return 'error';
    }
    return 'content';
  }

  void _invalidateDerived() {
    _derivedCacheKey = null;
    _cachedDerived = null;
  }

  void setUserLocationHint({
    required double latitude,
    required double longitude,
  }) {
    if (!_alive) return;
    if (state.userLatitude == latitude && state.userLongitude == longitude) {
      return;
    }
    _invalidateDerived();
    state = state.copyWith(userLatitude: latitude, userLongitude: longitude);
  }

  /// Unapproved events are organizer-only; keeps hero/sections safe if bad data slips in.
  bool _visibleInPublicDiscovery(EcoEvent e) =>
      e.moderationApproved || e.isOrganizer;

  int _eventsFingerprint(List<EcoEvent> list) {
    int h = list.length;
    for (final EcoEvent e in list) {
      h = h * 31 + e.id.hashCode;
    }
    return h;
  }

  String _filteredMemoKey(AppLocalizations? l10n) =>
      '${_eventsFingerprint(events)}|${state.activeFilter}|${state.searchQuery}|${l10n?.localeName ?? ''}|${state.repositoryEpoch}|${state.userLatitude?.toStringAsFixed(4)}|${state.userLongitude?.toStringAsFixed(4)}';

  /// Single server refresh path for the active chip + advanced filters + cleared global list when empty.
  Future<void> refreshMergedList() async {
    final EcoEventSearchParams merged = EventsFeedSearchMerge.mergedForChip(
      state.activeSearchParams,
      state.activeFilter,
    );
    await _repository.refreshEvents(params: merged.isEmpty ? null : merged);
    _invalidateDerived();
    state = state.copyWith(repositoryEpoch: state.repositoryEpoch + 1);
  }

  /// Pull-to-refresh: clears [initialLoadError] after a successful round-trip (matches feed screen UX).
  Future<bool> userPullRefresh() async {
    try {
      await refreshMergedList();
      state = state.copyWith(
        clearInitialLoadError: true,
        clearLastPullRefreshError: true,
      );
      return true;
    } on AppError catch (e) {
      state = state.copyWith(lastPullRefreshError: e);
      return false;
    } on Object catch (e) {
      state = state.copyWith(lastPullRefreshError: AppError.unknown(cause: e));
      return false;
    }
  }

  Future<void> loadInitial({
    required String initialListEmptyErrorMessage,
  }) async {
    final Future<void>? inFlight = _initialLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final Future<void> work = _runInitialLoad(
      initialListEmptyErrorMessage: initialListEmptyErrorMessage,
    );
    _initialLoadFuture = work;
    try {
      await work;
    } finally {
      if (identical(_initialLoadFuture, work)) {
        _initialLoadFuture = null;
      }
    }
  }

  Future<void> _runInitialLoad({
    required String initialListEmptyErrorMessage,
  }) async {
    state = state.copyWith(clearInitialLoadError: true, isInitialLoading: true);
    try {
      final EcoEventFilter saved = await _discoveryPreferences
          .readActiveFilter();
      if (!_alive) {
        return;
      }
      if (state.activeFilter != saved) {
        state = state.copyWith(activeFilter: saved);
      }
      _repository.loadInitialIfNeeded();
      await _repository.ready;
      if (!_alive) {
        return;
      }
      if (events.isEmpty && _repository.lastGlobalListLoadFailed) {
        state = state.copyWith(
          initialLoadError: AppError.network(
            message: initialListEmptyErrorMessage,
          ),
          isInitialLoading: false,
        );
        return;
      }

      final EcoEventSearchParams mergedForList =
          EventsFeedSearchMerge.mergedForChip(
            state.activeSearchParams,
            state.activeFilter,
          );
      if (!mergedForList.isEmpty) {
        try {
          await _repository.refreshEvents(params: mergedForList);
          if (!_alive) {
            return;
          }
          _invalidateDerived();
          state = state.copyWith(repositoryEpoch: state.repositoryEpoch + 1);
        } on Object catch (_) {
          // Keep bootstrap list; user can pull to refresh.
        }
      }
    } on Object catch (e) {
      if (_alive) {
        state = state.copyWith(initialLoadError: AppError.network(cause: e));
      }
    } finally {
      if (_alive && state.isInitialLoading) {
        _invalidateDerived();
        state = state.copyWith(isInitialLoading: false);
      }
    }
  }

  Future<void> loadRecentSearches() async {
    final List<String> recent = await _discoveryPreferences
        .readRecentSearches();
    if (!_alive) return;
    state = state.copyWith(recentSearches: recent);
  }

  Future<void> rememberSearch(String value) async {
    final String q = value.trim();
    if (q.length < 2) {
      return;
    }
    final List<String> next = <String>[
      q,
      ...state.recentSearches.where(
        (String existing) => existing.toLowerCase() != q.toLowerCase(),
      ),
    ];
    await _discoveryPreferences.writeRecentSearches(next);
    if (!_alive) return;
    state = state.copyWith(
      recentSearches: next.take(8).toList(growable: false),
    );
  }

  void onSearchTextChanged(
    String value, {
    Duration debounce = const Duration(milliseconds: 400),
  }) {
    _invalidateDerived();
    state = state.copyWith(searchQuery: value);
    final EcoEventSearchParams merged = EventsFeedSearchMerge.mergedForChip(
      state.activeSearchParams,
      state.activeFilter,
    );
    ref
        .read(eventsSearchControllerProvider.notifier)
        .scheduleTextSearch(
          rawText: value,
          mergedBase: merged,
          debounce: debounce,
        );
  }

  Future<bool> clearSearchField() async {
    ref.read(eventsSearchControllerProvider.notifier).cancel();
    ref.read(eventsSearchControllerProvider.notifier).clearPhase();
    searchController.clear();
    _invalidateDerived();
    state = state.copyWith(searchQuery: '');
    return setSearchParams(state.activeSearchParams.copyWith(clearQuery: true));
  }

  /// Updates server search params and refreshes. Returns `false` if refresh threw.
  Future<bool> setSearchParams(EcoEventSearchParams next) async {
    if (next == state.activeSearchParams) {
      return true;
    }
    state = state.copyWith(activeSearchParams: next);
    try {
      await refreshMergedList();
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Applies a recent-search chip: syncs [searchController], search query for UI,
  /// persisted recents, and server [EcoEventSearchParams.query] (same as debounced typing).
  Future<bool> applySearchSuggestion(String suggestion) async {
    final String trimmed = suggestion.trim();
    searchController.text = trimmed;
    searchController.selection = TextSelection.collapsed(
      offset: searchController.text.length,
    );
    ref.read(eventsSearchControllerProvider.notifier).cancel();
    _invalidateDerived();
    state = state.copyWith(searchQuery: trimmed);
    await rememberSearch(trimmed);
    return setSearchParams(
      state.activeSearchParams.copyWith(
        query: trimmed.isEmpty ? null : trimmed,
        clearQuery: trimmed.isEmpty,
      ),
    );
  }

  // ignore: avoid_positional_boolean_parameters, boolean setter whose call sites include app tests outside this package's edit scope
  void setCalendarView(bool value) {
    if (state.calendarView == value) {
      return;
    }
    state = state.copyWith(calendarView: value);
    unawaited(_discoveryPreferences.writeCalendarViewPreferred(value));
  }

  Future<void> loadCalendarViewPreference() async {
    final bool preferred = await _discoveryPreferences
        .readCalendarViewPreferred();
    if (!_alive || state.calendarView == preferred) {
      return;
    }
    state = state.copyWith(calendarView: preferred);
  }

  Future<bool> setActiveFilter(EcoEventFilter filter) async {
    if (filter == state.activeFilter) {
      return true;
    }
    final EcoEventFilter previous = state.activeFilter;
    final bool serverGroupChanged =
        EventsFeedSearchMerge.serverFetchGroup(previous) !=
        EventsFeedSearchMerge.serverFetchGroup(filter);

    state = state.copyWith(activeFilter: filter);
    _invalidateDerived();
    state = state.copyWith(repositoryEpoch: state.repositoryEpoch + 1);

    unawaited(_discoveryPreferences.writeActiveFilter(filter));

    if (!serverGroupChanged) {
      return true;
    }

    unawaited(
      refreshMergedList().catchError((Object _) {
        // Keep showing the client-filtered in-memory snapshot; pull-to-refresh retries.
      }),
    );
    return true;
  }

  /// Resets chip to [EcoEventFilter.all], clears advanced sheet params, and clears search.
  Future<bool> resetAllDiscoveryFilters() async {
    ref.read(eventsSearchControllerProvider.notifier).cancel();
    searchController.clear();
    _invalidateDerived();
    state = state.copyWith(
      activeFilter: EcoEventFilter.all,
      activeSearchParams: const EcoEventSearchParams(),
      searchQuery: '',
    );
    try {
      await refreshMergedList();
      await _discoveryPreferences.writeActiveFilter(EcoEventFilter.all);
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  List<EcoEvent> filteredEvents(AppLocalizations l10n) {
    return _derived(l10n).filtered;
  }

  /// In-progress rows for sectioned feed (from full [events], not client-filtered list).
  List<EcoEvent> get happeningNow => _derivedWithoutL10n().happeningNow;

  /// Upcoming rows for hero + sections (from full [events]).
  List<EcoEvent> get comingUp => _derivedWithoutL10n().comingUp;

  List<EcoEvent> get recentlyCompleted => _derivedWithoutL10n().recentlyCompleted;

  EcoEvent? get heroEvent => _derivedWithoutL10n().hero;

  _EventsFeedDerived _derivedWithoutL10n() => _derived(null);

  _EventsFeedDerived _derived(AppLocalizations? l10n) {
    final String key = _filteredMemoKey(l10n);
    if (_derivedCacheKey == key && _cachedDerived != null) {
      return _cachedDerived!;
    }
    _derivedCacheKey = key;
    _cachedDerived = _computeDerived();
    return _cachedDerived!;
  }

  _EventsFeedDerived _computeDerived() {
    final List<EcoEvent> filtered = _computeFiltered();
    final List<EcoEvent> happeningNowRows = events
        .where((EcoEvent e) => e.status == EcoEventStatus.inProgress)
        .where(_visibleInPublicDiscovery)
        .toList();
    final List<EcoEvent> comingUpRows = _applyDiscoverySort(
      events
          .where((EcoEvent e) => e.status == EcoEventStatus.upcoming)
          .where(_visibleInPublicDiscovery)
          .where(
            (EcoEvent e) =>
                e.isOrganizer || e.isJoined || e.canVolunteerJoinNow,
          )
          .toList(),
    );
    final List<EcoEvent> recentlyCompletedRows =
        events.where((EcoEvent e) => e.isPastForPublicDiscovery).toList()
          ..sort((EcoEvent a, EcoEvent b) => b.date.compareTo(a.date));
    final EcoEvent? hero =
        comingUpRows.isNotEmpty ? comingUpRows.first : null;
    return _EventsFeedDerived(
      filtered: filtered,
      happeningNow: happeningNowRows,
      comingUp: comingUpRows,
      recentlyCompleted: recentlyCompletedRows,
      hero: hero,
    );
  }

  List<EcoEvent> _applyDiscoverySort(List<EcoEvent> source) {
    final List<EcoEvent> sorted = List<EcoEvent>.from(source);
    sorted.sort((EcoEvent a, EcoEvent b) {
      final int rankCompare = _statusRank(a).compareTo(_statusRank(b));
      if (rankCompare != 0) {
        return rankCompare;
      }
      if (a.status == EcoEventStatus.completed ||
          a.status == EcoEventStatus.cancelled) {
        return b.date.compareTo(a.date);
      }
      final int timeCompare = a.startDateTime.compareTo(b.startDateTime);
      if (timeCompare != 0) {
        return timeCompare;
      }
      final int proximityCompare = _distanceForSort(
        a,
      ).compareTo(_distanceForSort(b));
      if (proximityCompare != 0) {
        return proximityCompare;
      }
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

  List<EcoEvent> _computeFiltered() {
    List<EcoEvent> list = _applyDiscoverySort(List<EcoEvent>.from(events));
    switch (state.activeFilter) {
      case EcoEventFilter.all:
        break;
      case EcoEventFilter.upcoming:
      case EcoEventFilter.past:
        list = EventsFeedSearchMerge.applyChipClientFilter(
          list,
          state.activeFilter,
          visibleInPublicDiscovery: _visibleInPublicDiscovery,
        );
      case EcoEventFilter.nearby:
        list.sort((EcoEvent a, EcoEvent b) {
          final int dist = _distanceForSort(a).compareTo(_distanceForSort(b));
          if (dist != 0) {
            return dist;
          }
          return a.startDateTime.compareTo(b.startDateTime);
        });
      case EcoEventFilter.myEvents:
        list = list.where((EcoEvent e) => e.isOrganizer || e.isJoined).toList();
    }
    return list;
  }

  double _distanceForSort(EcoEvent event) {
    final double base = event.siteDistanceKm;
    if (base > 0) {
      return base;
    }
    final double? lat = state.userLatitude;
    final double? lng = state.userLongitude;
    if (lat == null ||
        lng == null ||
        event.siteLat == null ||
        event.siteLng == null) {
      return double.infinity;
    }
    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      LatLng(lat, lng),
      LatLng(event.siteLat!, event.siteLng!),
    );
  }
}

class _EventsFeedDerived {
  const _EventsFeedDerived({
    required this.filtered,
    required this.happeningNow,
    required this.comingUp,
    required this.recentlyCompleted,
    required this.hero,
  });

  final List<EcoEvent> filtered;
  final List<EcoEvent> happeningNow;
  final List<EcoEvent> comingUp;
  final List<EcoEvent> recentlyCompleted;
  final EcoEvent? hero;
}
