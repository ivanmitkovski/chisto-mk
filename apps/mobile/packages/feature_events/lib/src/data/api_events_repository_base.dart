part of 'api_events_repository.dart';

/// Shared mutable state and helpers for [ApiEventsRepository] part files.
class _ApiEventsRepositoryBase extends ChangeNotifier {
  _ApiEventsRepositoryBase({required ApiClient client}) : _client = client;

  final ApiClient _client;
  final EventsLocalCache _cache = const EventsLocalCache();

  List<EcoEvent> _events = <EcoEvent>[];
  Completer<void>? _readyCompleter;
  bool _started = false;
  String? _nextCursor;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _lastGlobalListLoadFailed = false;
  bool _isShowingStaleCachedEvents = false;
  DateTime? _lastSuccessfulListRefreshAt;
  double? _userLatitudeHint;
  double? _userLongitudeHint;
  bool _lastListFetchIncludedLocationHint = false;
  List<String> _lastRankedSearchSuggestions = const <String>[];
  EcoEventSearchParams? _activeParams;

  /// Coalesces overlapping [refreshEvents] calls into a single network request.
  Future<void>? _activeRefresh;

  /// Guards optimistic mutations against double-submit from rapid taps.
  final Set<String> _mutationsInFlight = <String>{};

  bool _isSessionInvalidFailure(Object error) =>
      error is AppError && error.indicatesInvalidOrEndedSession;

  Future<void> _persistEventsDisk() async {
    await _cache.writeEvents(_events, forActiveListParams: _activeParams);
  }

  /// When a list fetch fails and memory is empty, restore the last successful
  /// snapshot for the same server params (if any).
  Future<void> _tryHydrateFromDiskAfterListFailure(
    EcoEventSearchParams? attemptedParams,
  ) async {
    if (_events.isNotEmpty) {
      return;
    }
    final List<EcoEvent>? recovered = await _cache.readEvents(
      forActiveListParams: attemptedParams,
    );
    if (recovered != null && recovered.isNotEmpty) {
      _events = recovered;
      _nextCursor = null;
      _hasMore = false;
    }
  }

  EcoEvent? findById(String id) {
    for (final EcoEvent event in _events) {
      if (event.id == id) {
        return event;
      }
    }
    return null;
  }

  EcoEvent? findBySiteAndTitle({
    required String siteId,
    required String title,
  }) {
    final String normalizedTitle = title.trim().toLowerCase();
    for (final EcoEvent event in _events) {
      if (event.siteId == siteId &&
          event.title.trim().toLowerCase() == normalizedTitle) {
        return event;
      }
    }
    return null;
  }

  void _replaceById(String id, EcoEvent next) {
    _events = _events
        .map((EcoEvent e) => e.id == id ? next : e)
        .toList(growable: false);
  }

  void _upsert(EcoEvent event) {
    final List<EcoEvent> next = _events
        .where((EcoEvent e) => e.id != event.id)
        .toList(growable: true);
    next.insert(0, event);
    _events = next;
  }

  void resetToSeed() {
    _events = <EcoEvent>[];
    _nextCursor = null;
    _hasMore = false;
    _lastGlobalListLoadFailed = false;
    _isShowingStaleCachedEvents = false;
    notifyListeners();
  }
}
