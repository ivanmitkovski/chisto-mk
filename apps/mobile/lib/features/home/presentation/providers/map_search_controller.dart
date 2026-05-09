import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

enum MapSearchRemotePhase { idle, loading, ready, error }

class MapSearchState {
  const MapSearchState({
    this.query = '',
    this.localResults = const <PollutionSite>[],
    this.remoteOnlyResults = const <PollutionSite>[],
    this.isDebouncingLocal = false,
    this.remotePhase = MapSearchRemotePhase.idle,
    this.remoteError,
    this.suggestions = const <String>[],
    this.geoIntent,
  });

  final String query;
  final List<PollutionSite> localResults;
  final List<PollutionSite> remoteOnlyResults;
  final bool isDebouncingLocal;
  final MapSearchRemotePhase remotePhase;
  final Object? remoteError;
  final List<String> suggestions;
  final SiteMapSearchGeoIntent? geoIntent;

  bool get hasQuery => query.trim().isNotEmpty;

  int get totalMatchCount => localResults.length + remoteOnlyResults.length;

  bool get hasRemoteWork =>
      remotePhase == MapSearchRemotePhase.loading ||
      remotePhase == MapSearchRemotePhase.ready ||
      remotePhase == MapSearchRemotePhase.error;

  MapSearchState copyWith({
    String? query,
    List<PollutionSite>? localResults,
    List<PollutionSite>? remoteOnlyResults,
    bool? isDebouncingLocal,
    MapSearchRemotePhase? remotePhase,
    Object? remoteError,
    bool clearRemoteError = false,
    List<String>? suggestions,
    bool clearSuggestions = false,
    SiteMapSearchGeoIntent? geoIntent,
    bool clearGeoIntent = false,
    bool clearRemoteResults = false,
  }) {
    return MapSearchState(
      query: query ?? this.query,
      localResults: localResults ?? this.localResults,
      remoteOnlyResults: clearRemoteResults
          ? const <PollutionSite>[]
          : (remoteOnlyResults ?? this.remoteOnlyResults),
      isDebouncingLocal: isDebouncingLocal ?? this.isDebouncingLocal,
      remotePhase: remotePhase ?? this.remotePhase,
      remoteError: clearRemoteError ? null : (remoteError ?? this.remoteError),
      suggestions: clearSuggestions
          ? const <String>[]
          : (suggestions ?? this.suggestions),
      geoIntent: clearGeoIntent ? null : (geoIntent ?? this.geoIntent),
    );
  }
}

class MapSearchController extends ChangeNotifier {
  MapSearchController({
    required Future<SiteMapSearchResponse> Function(SiteMapSearchRequest request)
        remoteSearch,
    List<PollutionSite> initialLocalPool = const <PollutionSite>[],
    SiteMapSearchFilterContext filterContext =
        const SiteMapSearchFilterContext(
      statuses: <String>[],
      pollutionTypes: <String>[],
      includeArchived: false,
    ),
    double? cameraLat,
    double? cameraLng,
    Duration localDebounce = const Duration(milliseconds: 220),
    Duration remoteDebounce = const Duration(milliseconds: 320),
    int remoteLimit = 24,
  })  : _remoteSearch = remoteSearch,
        _localPool = initialLocalPool,
        _filterContext = filterContext,
        _cameraLat = cameraLat,
        _cameraLng = cameraLng,
        _localDebounceDuration = localDebounce,
        _remoteDebounceDuration = remoteDebounce,
        _remoteLimit = remoteLimit,
        _state = MapSearchState(
          localResults: _computeLocalMatches('', initialLocalPool),
        );

  final Future<SiteMapSearchResponse> Function(SiteMapSearchRequest request)
      _remoteSearch;
  final Duration _localDebounceDuration;
  final Duration _remoteDebounceDuration;
  final int _remoteLimit;

  List<PollutionSite> _localPool;
  SiteMapSearchFilterContext _filterContext;
  double? _cameraLat;
  double? _cameraLng;

  Timer? _debounceLocal;
  Timer? _debounceRemote;
  int _remoteGen = 0;
  String _localPoolSig = '';

  MapSearchState _state;

  MapSearchState get state => _state;

  void setLocalPool(List<PollutionSite> sites) {
    final List<String> ids = sites.map((PollutionSite s) => s.id).toList()..sort();
    final String sig = ids.join('\u001f');
    if (sig == _localPoolSig && sites.length == _localPool.length) {
      return;
    }
    _localPoolSig = sig;
    _localPool = sites;
    _state = _state.copyWith(
      localResults: _computeLocalMatches(_state.query.trim(), _localPool),
      clearRemoteResults: true,
      remotePhase: MapSearchRemotePhase.idle,
      clearRemoteError: true,
      clearSuggestions: true,
      clearGeoIntent: true,
    );
    notifyListeners();
    _kickRemoteIfNeeded(_state.query.trim());
  }

  void setFilterContext(SiteMapSearchFilterContext ctx) {
    if (_filterContext.includeArchived == ctx.includeArchived &&
        _sortedStringListEq(_filterContext.statuses, ctx.statuses) &&
        _sortedStringListEq(_filterContext.pollutionTypes, ctx.pollutionTypes)) {
      return;
    }
    _filterContext = ctx;
    _kickRemoteIfNeeded(_state.query.trim());
  }

  void setCamera(double? lat, double? lng) {
    if (_cameraLat == lat && _cameraLng == lng) {
      return;
    }
    _cameraLat = lat;
    _cameraLng = lng;
    _kickRemoteIfNeeded(_state.query.trim());
  }

  void updateQuery(String rawQuery) {
    _debounceLocal?.cancel();
    _state = _state.copyWith(query: rawQuery, isDebouncingLocal: true);
    notifyListeners();
    _debounceLocal = Timer(_localDebounceDuration, () {
      final String trimmed = rawQuery.trim();
      final List<PollutionSite> local = _computeLocalMatches(trimmed, _localPool);
      _state = _state.copyWith(
        isDebouncingLocal: false,
        localResults: local,
      );
      notifyListeners();
      if (trimmed.length < 2) {
        _debounceRemote?.cancel();
        _remoteGen += 1;
        _state = _state.copyWith(
          clearRemoteResults: true,
          remotePhase: MapSearchRemotePhase.idle,
          clearRemoteError: true,
          clearSuggestions: true,
          clearGeoIntent: true,
        );
        notifyListeners();
        return;
      }
      _kickRemoteIfNeeded(trimmed);
    });
  }

  void clearQuery() => updateQuery('');

  void retryRemote() {
    final String q = _state.query.trim();
    if (q.length < 2) {
      return;
    }
    _kickRemoteIfNeeded(q, force: true);
  }

  void _kickRemoteIfNeeded(String trimmed, {bool force = false}) {
    if (trimmed.length < 2) {
      return;
    }
    _debounceRemote?.cancel();
    if (force) {
      unawaited(_runRemoteSearch(trimmed, ++_remoteGen));
      return;
    }
    _debounceRemote = Timer(_remoteDebounceDuration, () {
      unawaited(_runRemoteSearch(trimmed, ++_remoteGen));
    });
  }

  Future<void> _runRemoteSearch(String q, int gen) async {
    _state = _state.copyWith(
      remotePhase: MapSearchRemotePhase.loading,
      clearRemoteError: true,
      clearSuggestions: true,
      clearGeoIntent: true,
    );
    notifyListeners();
    try {
      final SiteMapSearchResponse res = await _remoteSearch(
        SiteMapSearchRequest(
          query: q,
          limit: _remoteLimit,
          lat: _cameraLat,
          lng: _cameraLng,
          statuses: _filterContext.statuses,
          pollutionTypes: _filterContext.pollutionTypes,
          includeArchived: _filterContext.includeArchived,
        ),
      );
      if (gen != _remoteGen) {
        return;
      }
      final Set<String> localIds =
          _state.localResults.map((PollutionSite s) => s.id).toSet();
      final List<PollutionSite> remoteOnly = res.items
          .where((PollutionSite s) => !localIds.contains(s.id))
          .toList();
      _state = _state.copyWith(
        remoteOnlyResults: remoteOnly,
        remotePhase: MapSearchRemotePhase.ready,
        suggestions: res.suggestions,
        geoIntent: res.geoIntent,
      );
    } catch (e) {
      if (gen != _remoteGen) {
        return;
      }
      _state = _state.copyWith(
        remotePhase: MapSearchRemotePhase.error,
        remoteError: e,
      );
    }
    notifyListeners();
  }

  static bool _sortedStringListEq(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    final List<String> sa = List<String>.from(a)..sort();
    final List<String> sb = List<String>.from(b)..sort();
    for (int i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) {
        return false;
      }
    }
    return true;
  }

  static List<PollutionSite> _computeLocalMatches(
    String rawQuery,
    List<PollutionSite> pool,
  ) {
    final String q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return List<PollutionSite>.from(pool);
    }
    final List<String> terms = q
        .split(RegExp(r'\s+'))
        .where((String t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) {
      return List<PollutionSite>.from(pool);
    }

    final List<PollutionSite> matches = pool.where((PollutionSite site) {
      final String title = site.title.toLowerCase();
      final String type = (site.pollutionType ?? '').toLowerCase();
      final String desc = site.description.toLowerCase();
      for (final String term in terms) {
        if (title.contains(term) || type.contains(term) || desc.contains(term)) {
          continue;
        }
        return false;
      }
      return true;
    }).toList();

    matches.sort((PollutionSite a, PollutionSite b) {
      final String aTitle = a.title.toLowerCase();
      final String bTitle = b.title.toLowerCase();
      final int aRank = aTitle == q ? 0 : (aTitle.startsWith(q) ? 1 : 2);
      final int bRank = bTitle == q ? 0 : (bTitle.startsWith(q) ? 1 : 2);
      if (aRank != bRank) {
        return aRank.compareTo(bRank);
      }
      return aTitle.compareTo(bTitle);
    });
    return matches;
  }

  @override
  void dispose() {
    _debounceLocal?.cancel();
    _debounceRemote?.cancel();
    super.dispose();
  }
}
