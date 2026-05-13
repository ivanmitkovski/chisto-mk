import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/features/events/data/events_discovery_preferences.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/controllers/events_search_controller.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_feed_search_merge.dart';
/// Owns feed discovery state: debounced ranked search, chip/server params, calendar toggle,
/// and **memoized** derived lists (nearby / my-events client sorts only; text match is server-side).
///
/// [Listenable]: attach from a screen with [addListener] + [setState], or [ListenableBuilder].
class EventsFeedController extends ChangeNotifier {
  EventsFeedController({
    required EventsRepository repository,
    EventsDiscoveryPreferences discoveryPreferences =
        const EventsDiscoveryPreferences(),
  })  : _repository = repository,
        _discoveryPreferences = discoveryPreferences {
    _repository.addListener(_onRepositoryUpdate);
    remoteSearch = EventsSearchController(
      runSearchParams: (EcoEventSearchParams next) => setSearchParams(next),
    );
  }

  final EventsRepository _repository;
  final EventsDiscoveryPreferences _discoveryPreferences;

  /// Debounced ranked search + phase for the discovery search field.
  late final EventsSearchController remoteSearch;

  final TextEditingController searchController = TextEditingController();

  EcoEventFilter _activeFilter = EcoEventFilter.all;
  EcoEventSearchParams _activeSearchParams = const EcoEventSearchParams();
  String _searchQuery = '';
  bool _calendarView = false;
  List<String> _recentSearches = const <String>[];
  bool _isInitialLoading = true;
  AppError? _initialLoadError;
  bool _disposed = false;

  String? _derivedCacheKey;
  List<EcoEvent>? _cachedFiltered;

  double? _userLatitude;
  double? _userLongitude;

  /// Set when [userPullRefresh] fails so the UI can show a typed message via [localizedAppErrorMessage].
  AppError? _lastPullRefreshError;

  EventsRepository get repository => _repository;

  AppError? get lastPullRefreshError => _lastPullRefreshError;

  bool get hasUserLocationHint => _userLatitude != null && _userLongitude != null;

  EcoEventFilter get activeFilter => _activeFilter;
  EcoEventSearchParams get activeSearchParams => _activeSearchParams;

  List<String> get rankedSearchSuggestions =>
      _repository.lastRankedSearchSuggestions;
  String get searchQuery => _searchQuery;
  bool get calendarView => _calendarView;
  List<String> get recentSearches => _recentSearches;
  bool get isInitialLoading => _isInitialLoading;
  AppError? get initialLoadError => _initialLoadError;

  List<EcoEvent> get events => _repository.events;

  bool get hasActiveFilters =>
      _activeFilter != EcoEventFilter.all ||
      _activeSearchParams.categories.isNotEmpty ||
      _activeSearchParams.statuses.isNotEmpty ||
      _activeSearchParams.dateFrom != null ||
      _activeSearchParams.dateTo != null;

  /// `loading` / `error` / `content` — matches [EventsFeedScreen] phase switcher.
  String feedPhase() {
    if (_isInitialLoading && events.isEmpty) {
      return 'loading';
    }
    if (_initialLoadError != null && events.isEmpty) {
      return 'error';
    }
    return 'content';
  }

  void _invalidateDerived() {
    _derivedCacheKey = null;
    _cachedFiltered = null;
  }

  void setUserLocationHint({
    required double latitude,
    required double longitude,
  }) {
    if (_userLatitude == latitude && _userLongitude == longitude) {
      return;
    }
    _userLatitude = latitude;
    _userLongitude = longitude;
    _invalidateDerived();
    notifyListeners();
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

  String _filteredMemoKey(AppLocalizations l10n) =>
      '${_eventsFingerprint(events)}|$_activeFilter|$_searchQuery|${l10n.localeName}';

  /// Single server refresh path for the active chip + advanced filters + cleared global list when empty.
  Future<void> refreshMergedList() async {
    final EcoEventSearchParams merged =
        EventsFeedSearchMerge.mergedForChip(_activeSearchParams, _activeFilter);
    await _repository.refreshEvents(
      params: merged.isEmpty ? null : merged,
    );
    _invalidateDerived();
    notifyListeners();
  }

  /// Pull-to-refresh: clears [initialLoadError] after a successful round-trip (matches feed screen UX).
  Future<bool> userPullRefresh() async {
    try {
      await refreshMergedList();
      _initialLoadError = null;
      _lastPullRefreshError = null;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _lastPullRefreshError = e;
      notifyListeners();
      return false;
    } on Object catch (e) {
      _lastPullRefreshError = AppError.unknown(cause: e);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadInitial({required String initialListEmptyErrorMessage}) async {
    void emitIfAlive() {
      if (_disposed) {
        return;
      }
      notifyListeners();
    }

    _initialLoadError = null;
    _isInitialLoading = true;
    emitIfAlive();
    try {
      final EcoEventFilter saved = await _discoveryPreferences.readActiveFilter();
      if (_disposed) {
        return;
      }
      if (_activeFilter != saved) {
        _activeFilter = saved;
        emitIfAlive();
      }
      _repository.loadInitialIfNeeded();
      await _repository.ready;
      if (_disposed) {
        return;
      }
      if (events.isEmpty && _repository.lastGlobalListLoadFailed) {
        _initialLoadError = AppError.network(
          message: initialListEmptyErrorMessage,
        );
        _isInitialLoading = false;
        _invalidateDerived();
        emitIfAlive();
        return;
      }
      _isInitialLoading = false;
      _invalidateDerived();
      emitIfAlive();

      final EcoEventSearchParams mergedForList =
          EventsFeedSearchMerge.mergedForChip(_activeSearchParams, _activeFilter);
      if (!mergedForList.isEmpty) {
        try {
          await _repository.refreshEvents(params: mergedForList);
          if (_disposed) {
            return;
          }
          _invalidateDerived();
          emitIfAlive();
        } on Object catch (_) {
          // Keep bootstrap list; user can pull to refresh.
        }
      }
    } on Object catch (e) {
      if (_disposed) {
        return;
      }
      _initialLoadError = AppError.network(cause: e);
      _isInitialLoading = false;
      _invalidateDerived();
      emitIfAlive();
    }
  }

  Future<void> loadRecentSearches() async {
    final List<String> recent = await _discoveryPreferences.readRecentSearches();
    _recentSearches = recent;
    notifyListeners();
  }

  Future<void> rememberSearch(String value) async {
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
    _recentSearches = next.take(8).toList(growable: false);
    notifyListeners();
  }

  void onSearchTextChanged(String value, {Duration debounce = const Duration(milliseconds: 400)}) {
    _searchQuery = value;
    _invalidateDerived();
    notifyListeners();
    final EcoEventSearchParams merged =
        EventsFeedSearchMerge.mergedForChip(_activeSearchParams, _activeFilter);
    remoteSearch.scheduleTextSearch(
      rawText: value,
      mergedBase: merged,
      debounce: debounce,
    );
  }

  Future<bool> clearSearchField() async {
    remoteSearch.cancel();
    remoteSearch.clearPhase();
    searchController.clear();
    _searchQuery = '';
    _invalidateDerived();
    notifyListeners();
    return setSearchParams(_activeSearchParams.copyWith(clearQuery: true));
  }

  /// Updates server search params and refreshes. Returns `false` if refresh threw.
  Future<bool> setSearchParams(EcoEventSearchParams next) async {
    if (next == _activeSearchParams) {
      return true;
    }
    _activeSearchParams = next;
    notifyListeners();
    try {
      await refreshMergedList();
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Applies a recent-search chip: syncs [searchController], client [_searchQuery],
  /// persisted recents, and server [EcoEventSearchParams.query] (same as debounced typing).
  Future<bool> applySearchSuggestion(String suggestion) async {
    final String trimmed = suggestion.trim();
    searchController.text = trimmed;
    searchController.selection =
        TextSelection.collapsed(offset: searchController.text.length);
    remoteSearch.cancel();
    _searchQuery = trimmed;
    _invalidateDerived();
    notifyListeners();
    await rememberSearch(trimmed);
    return setSearchParams(
      _activeSearchParams.copyWith(
        query: trimmed.isEmpty ? null : trimmed,
        clearQuery: trimmed.isEmpty,
      ),
    );
  }

  void setCalendarView(bool value) {
    if (_calendarView == value) {
      return;
    }
    _calendarView = value;
    notifyListeners();
    unawaited(_discoveryPreferences.writeCalendarViewPreferred(value));
  }

  Future<void> loadCalendarViewPreference() async {
    final bool preferred = await _discoveryPreferences.readCalendarViewPreferred();
    if (_calendarView == preferred) {
      return;
    }
    _calendarView = preferred;
    notifyListeners();
  }

  Future<bool> setActiveFilter(EcoEventFilter filter) async {
    _activeFilter = filter;
    _invalidateDerived();
    notifyListeners();
    try {
      await refreshMergedList();
      await _discoveryPreferences.writeActiveFilter(filter);
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Resets chip to [EcoEventFilter.all], clears advanced sheet params, and clears search.
  Future<bool> resetAllDiscoveryFilters() async {
    remoteSearch.cancel();
    _activeFilter = EcoEventFilter.all;
    _activeSearchParams = const EcoEventSearchParams();
    _searchQuery = '';
    searchController.clear();
    _invalidateDerived();
    notifyListeners();
    try {
      await refreshMergedList();
      await _discoveryPreferences.writeActiveFilter(EcoEventFilter.all);
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  void _onRepositoryUpdate() {
    void applyUpdate() {
      if (events.isNotEmpty && _initialLoadError != null) {
        _initialLoadError = null;
      }
      _invalidateDerived();
      notifyListeners();
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
      return;
    }
    applyUpdate();
  }

  List<EcoEvent> filteredEvents(AppLocalizations l10n) {
    final String key = _filteredMemoKey(l10n);
    if (_derivedCacheKey == key && _cachedFiltered != null) {
      return _cachedFiltered!;
    }
    _derivedCacheKey = key;
    _cachedFiltered = _computeFiltered(l10n);
    return _cachedFiltered!;
  }

  List<EcoEvent> _applyDiscoverySort(List<EcoEvent> source) {
    final List<EcoEvent> sorted = List<EcoEvent>.from(source);
    sorted.sort((EcoEvent a, EcoEvent b) {
      final int rankCompare = _statusRank(a).compareTo(_statusRank(b));
      if (rankCompare != 0) {
        return rankCompare;
      }
      if (a.status == EcoEventStatus.completed || a.status == EcoEventStatus.cancelled) {
        return b.date.compareTo(a.date);
      }
      final int timeCompare = a.startDateTime.compareTo(b.startDateTime);
      if (timeCompare != 0) {
        return timeCompare;
      }
      final int proximityCompare = _distanceForSort(a).compareTo(_distanceForSort(b));
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

  List<EcoEvent> _computeFiltered(AppLocalizations _) {
    List<EcoEvent> list = _applyDiscoverySort(List<EcoEvent>.from(events));
    switch (_activeFilter) {
      case EcoEventFilter.all:
      case EcoEventFilter.upcoming:
      case EcoEventFilter.past:
        break;
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

  /// In-progress rows for sectioned feed (from full [events], not client-filtered list).
  List<EcoEvent> get happeningNow => events
      .where((EcoEvent e) => e.status == EcoEventStatus.inProgress)
      .where(_visibleInPublicDiscovery)
      .toList();

  /// Upcoming rows for hero + sections (from full [events]).
  List<EcoEvent> get comingUp => _applyDiscoverySort(
        events
            .where((EcoEvent e) => e.status == EcoEventStatus.upcoming)
            .where(_visibleInPublicDiscovery)
            .toList(),
      );

  List<EcoEvent> get recentlyCompleted => events
          .where(
            (EcoEvent e) =>
                e.status == EcoEventStatus.completed ||
                e.status == EcoEventStatus.cancelled,
          )
          .toList()
        ..sort((EcoEvent a, EcoEvent b) => b.date.compareTo(a.date));

  EcoEvent? get heroEvent => comingUp.isNotEmpty ? comingUp.first : null;

  @override
  void dispose() {
    _disposed = true;
    remoteSearch.dispose();
    _repository.removeListener(_onRepositoryUpdate);
    searchController.dispose();
    super.dispose();
  }

  double _distanceForSort(EcoEvent event) {
    final double base = event.siteDistanceKm;
    if (base > 0) {
      return base;
    }
    if (_userLatitude == null ||
        _userLongitude == null ||
        event.siteLat == null ||
        event.siteLng == null) {
      return double.infinity;
    }
    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      LatLng(_userLatitude!, _userLongitude!),
      LatLng(event.siteLat!, event.siteLng!),
    );
  }
}
