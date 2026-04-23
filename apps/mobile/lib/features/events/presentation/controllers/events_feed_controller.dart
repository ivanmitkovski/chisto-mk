import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/features/events/data/events_discovery_preferences.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_feed_search_merge.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';

/// Owns feed discovery state: debounced search, chip/server params, calendar toggle,
/// and **memoized** derived lists (nearby / my-events sorts and client-side query filter).
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
  }

  final EventsRepository _repository;
  final EventsDiscoveryPreferences _discoveryPreferences;

  final TextEditingController searchController = TextEditingController();

  EcoEventFilter _activeFilter = EcoEventFilter.all;
  EcoEventSearchParams _activeSearchParams = const EcoEventSearchParams();
  String _searchQuery = '';
  bool _calendarView = false;
  List<String> _recentSearches = const <String>[];
  bool _isInitialLoading = true;
  AppError? _initialLoadError;
  Timer? _debounce;

  String? _derivedCacheKey;
  List<EcoEvent>? _cachedFiltered;

  List<EcoEvent> _discoveryThisWeekShelf = <EcoEvent>[];
  bool _discoveryThisWeekShelfLoading = false;
  bool _discoveryThisWeekShelfFailed = false;

  /// Set when [userPullRefresh] fails so the UI can show a typed message via [localizedAppErrorMessage].
  AppError? _lastPullRefreshError;

  EventsRepository get repository => _repository;

  AppError? get lastPullRefreshError => _lastPullRefreshError;

  List<EcoEvent> get discoveryThisWeekShelf =>
      List<EcoEvent>.unmodifiable(_discoveryThisWeekShelf);

  bool get discoveryThisWeekShelfFailed => _discoveryThisWeekShelfFailed;

  EcoEventFilter get activeFilter => _activeFilter;
  EcoEventSearchParams get activeSearchParams => _activeSearchParams;
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
      await loadDiscoveryThisWeekShelf();
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

  /// Loads the horizontal "this week (Skopje)" discovery strip without mutating the main feed query.
  Future<void> loadDiscoveryThisWeekShelf() async {
    if (_discoveryThisWeekShelfLoading) {
      return;
    }
    _discoveryThisWeekShelfLoading = true;
    _discoveryThisWeekShelfFailed = false;
    notifyListeners();
    try {
      final EcoEventSearchParams params = EcoEventSearchParams.discoveryThisSkopjeCalendarWeek(
        DateTime.now().toUtc(),
      );
      final List<EcoEvent> rows = await _repository.fetchEventsSnapshot(params);
      final List<EcoEvent> sorted = List<EcoEvent>.from(rows)
        ..sort((EcoEvent a, EcoEvent b) {
          final int dist = a.siteDistanceKm.compareTo(b.siteDistanceKm);
          if (dist != 0) {
            return dist;
          }
          return _statusRank(a).compareTo(_statusRank(b));
        });
      _discoveryThisWeekShelf = sorted;
    } on Object catch (_) {
      _discoveryThisWeekShelfFailed = true;
      _discoveryThisWeekShelf = <EcoEvent>[];
      logEventsDiagnostic('discovery_week_shelf_fetch_failed');
    } finally {
      _discoveryThisWeekShelfLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInitial({required String initialListEmptyErrorMessage}) async {
    _initialLoadError = null;
    _isInitialLoading = true;
    notifyListeners();
    try {
      _repository.loadInitialIfNeeded();
      await _repository.ready;
      if (events.isEmpty && _repository.lastGlobalListLoadFailed) {
        _initialLoadError = AppError.network(
          message: initialListEmptyErrorMessage,
        );
        _isInitialLoading = false;
        _invalidateDerived();
        notifyListeners();
        return;
      }
      _isInitialLoading = false;
      _invalidateDerived();
      notifyListeners();

      final EcoEventSearchParams mergedForList =
          EventsFeedSearchMerge.mergedForChip(_activeSearchParams, _activeFilter);
      if (!mergedForList.isEmpty) {
        try {
          await _repository.refreshEvents(params: mergedForList);
          _invalidateDerived();
          notifyListeners();
        } on Object catch (_) {
          // Keep bootstrap list; user can pull to refresh.
        }
      }
      unawaited(loadDiscoveryThisWeekShelf());
    } on Object catch (e) {
      _initialLoadError = AppError.network(cause: e);
      _isInitialLoading = false;
      _invalidateDerived();
      notifyListeners();
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
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      _searchQuery = value;
      _invalidateDerived();
      notifyListeners();
      unawaited(
        setSearchParams(
          _activeSearchParams.copyWith(
            query: value.isEmpty ? null : value,
            clearQuery: value.isEmpty,
          ),
        ),
      );
    });
  }

  Future<bool> clearSearchField() async {
    _debounce?.cancel();
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
    _debounce?.cancel();
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
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Resets chip to [EcoEventFilter.all], clears advanced sheet params, and clears search.
  Future<bool> resetAllDiscoveryFilters() async {
    _debounce?.cancel();
    _activeFilter = EcoEventFilter.all;
    _activeSearchParams = const EcoEventSearchParams();
    _searchQuery = '';
    searchController.clear();
    _invalidateDerived();
    notifyListeners();
    try {
      await refreshMergedList();
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

  List<EcoEvent> _computeFiltered(AppLocalizations l10n) {
    List<EcoEvent> list = _applyDiscoverySort(List<EcoEvent>.from(events));
    switch (_activeFilter) {
      case EcoEventFilter.all:
      case EcoEventFilter.upcoming:
      case EcoEventFilter.past:
        break;
      case EcoEventFilter.nearby:
        list.sort((EcoEvent a, EcoEvent b) {
          final int dist = a.siteDistanceKm.compareTo(b.siteDistanceKm);
          if (dist != 0) {
            return dist;
          }
          return a.startDateTime.compareTo(b.startDateTime);
        });
      case EcoEventFilter.myEvents:
        list = list.where((EcoEvent e) => e.isOrganizer || e.isJoined).toList();
    }
    if (_searchQuery.trim().isEmpty) {
      return list;
    }
    final String q = _searchQuery.trim().toLowerCase();
    return _applyDiscoverySort(
      list
          .where(
            (EcoEvent e) =>
                e.title.toLowerCase().contains(q) ||
                e.siteName.toLowerCase().contains(q) ||
                e.category.localizedLabel(l10n).toLowerCase().contains(q),
          )
          .toList(),
    );
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
    _debounce?.cancel();
    _repository.removeListener(_onRepositoryUpdate);
    searchController.dispose();
    super.dispose();
  }
}
