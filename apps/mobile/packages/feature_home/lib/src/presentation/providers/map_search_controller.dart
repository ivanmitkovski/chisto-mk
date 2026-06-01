import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/providers/map_camera_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_derived_providers.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/utils/map_search_text.dart';
import 'package:feature_home/src/presentation/utils/pollution_site_search.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_search_controller.g.dart';

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

  /// Matches [SiteMapSearchDto] / API minimum query length.
  static const int minRemoteQueryLength = 2;

  final String query;
  final List<PollutionSite> localResults;
  final List<PollutionSite> remoteOnlyResults;
  final bool isDebouncingLocal;
  final MapSearchRemotePhase remotePhase;
  final Object? remoteError;
  final List<String> suggestions;
  final SiteMapSearchGeoIntent? geoIntent;

  bool get hasQuery => query.trim().isNotEmpty;

  int get trimmedQueryLength => query.trim().length;

  bool get isQueryTooShortForRemote =>
      hasQuery && trimmedQueryLength < minRemoteQueryLength;

  bool get isSearching {
    if (!hasQuery || isQueryTooShortForRemote) {
      return false;
    }
    return isDebouncingLocal || remotePhase == MapSearchRemotePhase.loading;
  }

  bool get shouldShowNoResults =>
      hasQuery &&
      !isQueryTooShortForRemote &&
      !isSearching &&
      remotePhase == MapSearchRemotePhase.ready &&
      totalMatchCount == 0;

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

SiteMapSearchFilterContext _filterContextFrom(MapFilterState f) {
  return SiteMapSearchFilterContext(
    statuses: f.activeStatuses.map(mapStatusCodeFromUnknown).toList(),
    pollutionTypes: f.activePollutionTypes
        .map(reportPollutionTypeCodeFromUnknown)
        .toList(),
    includeArchived: f.includeArchived,
  );
}

@riverpod
class MapSearchController extends _$MapSearchController {
  Timer? _debounceLocal;
  Timer? _debounceRemote;
  int _remoteGen = 0;
  String _localPoolSig = '';
  RequestCancellationToken? _activeSearchCancellation;

  List<PollutionSite> _localPool = const <PollutionSite>[];
  SiteMapSearchFilterContext _filterContext = const SiteMapSearchFilterContext(
    statuses: <String>[],
    pollutionTypes: <String>[],
    includeArchived: false,
  );
  double? _cameraLat;
  double? _cameraLng;

  static const Duration _localDebounceDuration = Duration(milliseconds: 220);
  static const Duration _remoteDebounceDuration = Duration(milliseconds: 320);
  static const int _remoteLimit = 24;

  @override
  MapSearchState build() {
    final List<PollutionSite> initialPool = ref.read(
      mapSearchLocalPoolProvider,
    );
    final MapFilterState filter = ref.read(mapFilterNotifierProvider);
    final MapCameraState camera = ref.read(mapCameraNotifierProvider);

    _localPool = initialPool;
    _filterContext = _filterContextFrom(filter);
    _cameraLat = camera.centerLat;
    _cameraLng = camera.centerLng;

    ref.listen<List<PollutionSite>>(mapSearchLocalPoolProvider, (
      List<PollutionSite>? _,
      List<PollutionSite> next,
    ) {
      setLocalPool(next);
    });
    ref.listen<MapCameraState>(mapCameraNotifierProvider, (
      MapCameraState? _,
      MapCameraState next,
    ) {
      setCamera(next.centerLat, next.centerLng);
    });
    ref.listen<MapFilterState>(mapFilterNotifierProvider, (
      MapFilterState? _,
      MapFilterState next,
    ) {
      setFilterContext(_filterContextFrom(next));
    });

    ref.onDispose(_dispose);

    return MapSearchState(localResults: _computeLocalMatches('', initialPool));
  }

  void setLocalPool(List<PollutionSite> sites) {
    final List<String> ids = sites.map((PollutionSite s) => s.id).toList()
      ..sort();
    final String sig = ids.join('\u001f');
    if (sig == _localPoolSig && sites.length == _localPool.length) {
      return;
    }
    _localPoolSig = sig;
    _localPool = sites;
    final String trimmed = state.query.trim();
    state = state.copyWith(
      localResults: _computeLocalMatches(trimmed, _localPool),
      clearRemoteResults: true,
      remotePhase: trimmed.length >= MapSearchState.minRemoteQueryLength
          ? MapSearchRemotePhase.loading
          : MapSearchRemotePhase.idle,
      clearRemoteError: true,
      clearSuggestions: true,
      clearGeoIntent: true,
    );
    _kickRemoteIfNeeded(trimmed);
  }

  void setFilterContext(SiteMapSearchFilterContext ctx) {
    if (_filterContext.includeArchived == ctx.includeArchived &&
        _sortedStringListEq(_filterContext.statuses, ctx.statuses) &&
        _sortedStringListEq(
          _filterContext.pollutionTypes,
          ctx.pollutionTypes,
        )) {
      return;
    }
    _filterContext = ctx;
    _kickRemoteIfNeeded(state.query.trim());
  }

  void setCamera(double? lat, double? lng) {
    if (_cameraLat == lat && _cameraLng == lng) {
      return;
    }
    _cameraLat = lat;
    _cameraLng = lng;
  }

  void updateQuery(String rawQuery) {
    _debounceLocal?.cancel();
    final String trimmed = rawQuery.trim();
    final String previousTrimmed = state.query.trim();
    final bool trimmedChanged = trimmed != previousTrimmed;
    if (trimmedChanged) {
      _debounceRemote?.cancel();
      _remoteGen += 1;
    }

    final bool willSearchRemote =
        trimmed.length >= MapSearchState.minRemoteQueryLength;

    state = state.copyWith(
      query: rawQuery,
      isDebouncingLocal: true,
      remotePhase: willSearchRemote
          ? MapSearchRemotePhase.loading
          : MapSearchRemotePhase.idle,
      clearRemoteResults:
          trimmedChanged && (trimmed.isEmpty || willSearchRemote),
      clearRemoteError: trimmedChanged,
      clearSuggestions: trimmedChanged,
      clearGeoIntent: trimmedChanged,
    );
    _debounceLocal = Timer(_localDebounceDuration, () {
      final String currentTrimmed = rawQuery.trim();
      final List<PollutionSite> local = _computeLocalMatches(
        currentTrimmed,
        _localPool,
      );
      state = state.copyWith(isDebouncingLocal: false, localResults: local);
      if (currentTrimmed.length < MapSearchState.minRemoteQueryLength) {
        _debounceRemote?.cancel();
        _remoteGen += 1;
        state = state.copyWith(
          clearRemoteResults: true,
          remotePhase: MapSearchRemotePhase.idle,
          clearRemoteError: true,
          clearSuggestions: true,
          clearGeoIntent: true,
        );
        return;
      }
      _kickRemoteIfNeeded(currentTrimmed);
    });
  }

  void clearQuery() => updateQuery('');

  void retryRemote() {
    final String q = state.query.trim();
    if (q.length < MapSearchState.minRemoteQueryLength) {
      return;
    }
    _kickRemoteIfNeeded(q, force: true);
  }

  void _kickRemoteIfNeeded(String trimmed, {bool force = false}) {
    if (trimmed.length < MapSearchState.minRemoteQueryLength) {
      return;
    }
    _debounceRemote?.cancel();
    state = state.copyWith(
      remotePhase: MapSearchRemotePhase.loading,
      clearRemoteError: true,
    );
    if (force) {
      unawaited(_runRemoteSearch(trimmed, ++_remoteGen));
      return;
    }
    _debounceRemote = Timer(_remoteDebounceDuration, () {
      unawaited(_runRemoteSearch(trimmed, ++_remoteGen));
    });
  }

  Future<void> _runRemoteSearch(String q, int gen) async {
    _activeSearchCancellation?.cancel();
    final RequestCancellationToken cancellation = RequestCancellationToken();
    _activeSearchCancellation = cancellation;

    state = state.copyWith(
      clearRemoteError: true,
      clearSuggestions: true,
      clearGeoIntent: true,
    );
    try {
      final SiteMapSearchResponse res = await ref
          .read(sitesRepositoryProvider)
          .searchSitesForMap(
            SiteMapSearchRequest(
              query: q,
              limit: _remoteLimit,
              lat: _cameraLat,
              lng: _cameraLng,
              statuses: _filterContext.statuses,
              pollutionTypes: _filterContext.pollutionTypes,
              includeArchived: _filterContext.includeArchived,
            ),
            cancellation: cancellation,
          );
      if (gen != _remoteGen || cancellation.isCancelled) {
        return;
      }
      final Set<String> localIds = state.localResults
          .map((PollutionSite s) => s.id)
          .toSet();
      final List<PollutionSite> remoteOnly = res.items
          .where((PollutionSite s) => !localIds.contains(s.id))
          .toList();
      state = state.copyWith(
        remoteOnlyResults: remoteOnly,
        remotePhase: MapSearchRemotePhase.ready,
        suggestions: res.suggestions,
        geoIntent: res.geoIntent,
      );
    } catch (e) {
      if (gen != _remoteGen || cancellation.isCancelled) {
        return;
      }
      if (e is AppError && e.code == 'CANCELLED') {
        return;
      }
      state = state.copyWith(
        remotePhase: MapSearchRemotePhase.error,
        remoteError: e,
      );
    } finally {
      if (identical(_activeSearchCancellation, cancellation)) {
        _activeSearchCancellation = null;
      }
    }
  }

  void _dispose() {
    _debounceLocal?.cancel();
    _debounceRemote?.cancel();
    _remoteGen += 1;
    _activeSearchCancellation?.cancel();
    _activeSearchCancellation = null;
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
    final String q = normalizeMapSearchText(rawQuery);
    if (q.isEmpty) {
      return List<PollutionSite>.from(pool);
    }
    final List<String> terms = mapSearchTerms(rawQuery);
    if (terms.isEmpty) {
      return List<PollutionSite>.from(pool);
    }

    final List<PollutionSite> matches = pool
        .where(
          (PollutionSite site) => pollutionSiteMatchesSearchTerms(site, terms),
        )
        .toList();

    matches.sort((PollutionSite a, PollutionSite b) {
      final int aRank = mapSearchTitleRank(a.title, rawQuery);
      final int bRank = mapSearchTitleRank(b.title, rawQuery);
      if (aRank != bRank) {
        return aRank.compareTo(bRank);
      }
      return foldMapSearchText(a.title).compareTo(foldMapSearchText(b.title));
    });
    return matches;
  }
}
