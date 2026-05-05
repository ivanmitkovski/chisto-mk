import 'dart:async';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/utils/feed_visible_sites.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _feedFilterPrefsKey = 'feed_active_filter_v1';

/// Maps UI filters to [ListSitesQueryDto] (`sort`: hybrid|recent, `mode`: for_you|latest).
/// Server has no `most_voted`, `saved`, or `urgent` list modes — those stay client-side in
/// [computeVisibleSitesForFilter]; we only tune which ranked window we fetch.
({String sort, String mode, double radiusKm}) _feedApiParams(FeedFilter filter) {
  switch (filter) {
    case FeedFilter.recent:
      return (sort: 'recent', mode: 'latest', radiusKm: 100.0);
    case FeedFilter.nearby:
      return (sort: 'hybrid', mode: 'for_you', radiusKm: 25.0);
    case FeedFilter.urgent:
      return (sort: 'recent', mode: 'latest', radiusKm: 100.0);
    case FeedFilter.all:
    case FeedFilter.mostVoted:
    case FeedFilter.saved:
      return (sort: 'hybrid', mode: 'for_you', radiusKm: 100.0);
  }
}

/// Server pagination identity: when this changes, the feed list must be reloaded.
int feedServerFetchGroup(FeedFilter filter) {
  switch (filter) {
    case FeedFilter.recent:
      return 1;
    case FeedFilter.nearby:
      return 2;
    case FeedFilter.urgent:
      return 3;
    case FeedFilter.all:
    case FeedFilter.mostVoted:
    case FeedFilter.saved:
      return 0;
  }
}

enum FeedSitesViewStatus {
  initialLoading,
  freshData,
  staleData,
  empty,
  noLocation,
  firstLoadError,
  paginating,
  paginationError,
}

/// Stable per-tab session id for feed analytics (one id per provider lifetime).
final feedSessionIdProvider = Provider<String>((Ref ref) {
  ref.keepAlive();
  final AuthState auth = ref.watch(homeAuthStateProvider);
  final String userId = auth.userId ?? 'anon';
  return 'feed_${DateTime.now().millisecondsSinceEpoch}_$userId';
});

final feedFilterProvider =
    StateNotifierProvider<FeedFilterNotifier, FeedFilter>((Ref ref) {
  ref.keepAlive();
  return FeedFilterNotifier();
});

class FeedFilterNotifier extends StateNotifier<FeedFilter> {
  FeedFilterNotifier() : super(FeedFilter.all) {
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_feedFilterPrefsKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      for (final FeedFilter f in FeedFilter.values) {
        if (f.name == raw) {
          state = f;
          return;
        }
      }
    } catch (_) {
      // Keep default filter when local preferences are unavailable/corrupted.
    }
  }

  Future<void> setFilter(FeedFilter filter) async {
    state = filter;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_feedFilterPrefsKey, filter.name);
    } catch (_) {
      // Filter persistence failure should not block in-memory filter changes.
    }
  }
}

class FeedSitesState {
  const FeedSitesState({
    this.status = FeedSitesViewStatus.initialLoading,
    required this.allSites,
    required this.isLoading,
    this.loadError,
    this.nextCursor,
    required this.hasMore,
    required this.isLoadingMore,
    required this.loadMoreFailed,
    this.loadMoreError,
    required this.locationAvailable,
    this.userLatitude,
    this.userLongitude,
    this.feedVariant = 'v1',
    this.servedFromCache = false,
    this.isStaleFallback = false,
    this.cachedAt,
    this.lastSuccessfulRefreshAt,
  });

  final FeedSitesViewStatus status;
  final List<PollutionSite> allSites;
  final bool isLoading;
  final AppError? loadError;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final AppError? loadMoreError;
  final bool locationAvailable;
  final double? userLatitude;
  final double? userLongitude;
  final String feedVariant;
  final bool servedFromCache;
  final bool isStaleFallback;
  final DateTime? cachedAt;
  final DateTime? lastSuccessfulRefreshAt;

  static FeedSitesState initial() => const FeedSitesState(
        status: FeedSitesViewStatus.initialLoading,
        allSites: <PollutionSite>[],
        isLoading: true,
        hasMore: true,
        isLoadingMore: false,
        loadMoreFailed: false,
        locationAvailable: true,
        feedVariant: 'v1',
        servedFromCache: false,
        isStaleFallback: false,
      );

  FeedSitesState copyWith({
    FeedSitesViewStatus? status,
    List<PollutionSite>? allSites,
    bool? isLoading,
    AppError? loadError,
    bool clearLoadError = false,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    AppError? loadMoreError,
    bool clearLoadMoreError = false,
    bool? locationAvailable,
    double? userLatitude,
    double? userLongitude,
    String? feedVariant,
    bool? servedFromCache,
    bool? isStaleFallback,
    DateTime? cachedAt,
    DateTime? lastSuccessfulRefreshAt,
  }) {
    return FeedSitesState(
      status: status ?? this.status,
      allSites: allSites ?? this.allSites,
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      locationAvailable: locationAvailable ?? this.locationAvailable,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      feedVariant: feedVariant ?? this.feedVariant,
      servedFromCache: servedFromCache ?? this.servedFromCache,
      isStaleFallback: isStaleFallback ?? this.isStaleFallback,
      cachedAt: cachedAt ?? this.cachedAt,
      lastSuccessfulRefreshAt:
          lastSuccessfulRefreshAt ?? this.lastSuccessfulRefreshAt,
    );
  }
}

FeedSitesViewStatus _statusForLoadedResult({
  required List<PollutionSite> sites,
  required bool locationAvailable,
  required bool isStaleFallback,
}) {
  if (sites.isEmpty && !locationAvailable) {
    return FeedSitesViewStatus.noLocation;
  }
  if (isStaleFallback) {
    return FeedSitesViewStatus.staleData;
  }
  if (sites.isEmpty) {
    return FeedSitesViewStatus.empty;
  }
  return FeedSitesViewStatus.freshData;
}

final feedSitesNotifierProvider =
    StateNotifierProvider<FeedSitesNotifier, FeedSitesState>((Ref ref) {
  ref.keepAlive();
  return FeedSitesNotifier(ref);
});

class FeedSitesNotifier extends StateNotifier<FeedSitesState> {
  FeedSitesNotifier(this._ref) : super(FeedSitesState.initial());

  final Ref _ref;

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: state.allSites.isEmpty
          ? FeedSitesViewStatus.initialLoading
          : state.status,
      isLoading: true,
      clearLoadError: true,
      loadMoreFailed: false,
      clearLoadMoreError: true,
    );
    try {
      await _resolveUserLocation();
      final FeedFilter filter = _ref.read(feedFilterProvider);
      final ({String sort, String mode, double radiusKm}) api =
          _feedApiParams(filter);
      final result = await _ref.read(sitesRepositoryProvider).getSites(
            latitude: state.userLatitude,
            longitude: state.userLongitude,
            radiusKm: api.radiusKm,
            status: 'VERIFIED',
            page: 1,
            limit: 24,
            mode: api.mode,
            sort: api.sort,
            explain: true,
          );
      state = state.copyWith(
        status: _statusForLoadedResult(
          sites: result.sites,
          locationAvailable: state.locationAvailable,
          isStaleFallback: result.isStaleFallback,
        ),
        allSites: result.sites,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor?.isNotEmpty ?? false,
        isLoadingMore: false,
        loadMoreFailed: false,
        isLoading: false,
        clearLoadError: true,
        feedVariant: result.feedVariant,
        servedFromCache: result.servedFromCache,
        isStaleFallback: result.isStaleFallback,
        cachedAt: result.cachedAt,
        lastSuccessfulRefreshAt: result.servedFromCache
            ? state.lastSuccessfulRefreshAt
            : DateTime.now(),
      );
    } on AppError catch (e) {
      state = state.copyWith(
        status: state.allSites.isEmpty
            ? FeedSitesViewStatus.firstLoadError
            : FeedSitesViewStatus.staleData,
        loadError: e,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: state.allSites.isEmpty
            ? FeedSitesViewStatus.firstLoadError
            : FeedSitesViewStatus.staleData,
        loadError: AppError.network(cause: e),
        isLoading: false,
      );
    }
  }

  /// Returns `false` when the load failed (caller may show a snack).
  Future<bool> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) {
      return true;
    }
    state = state.copyWith(
      status: state.allSites.isEmpty
          ? FeedSitesViewStatus.initialLoading
          : FeedSitesViewStatus.paginating,
      isLoadingMore: true,
      loadMoreFailed: false,
      clearLoadMoreError: true,
    );
    try {
      final FeedFilter filter = _ref.read(feedFilterProvider);
      final ({String sort, String mode, double radiusKm}) api =
          _feedApiParams(filter);
      final result = await _ref.read(sitesRepositoryProvider).getSites(
            latitude: state.userLatitude,
            longitude: state.userLongitude,
            radiusKm: api.radiusKm,
            status: 'VERIFIED',
            page: 1,
            limit: 24,
            mode: api.mode,
            sort: api.sort,
            explain: true,
            cursor: state.nextCursor,
          );
      final Map<String, PollutionSite> mergedById = <String, PollutionSite>{
        for (final PollutionSite s in state.allSites) s.id: s,
      };
      for (final PollutionSite site in result.sites) {
        mergedById[site.id] = site;
      }
      state = state.copyWith(
        status: _statusForLoadedResult(
          sites: mergedById.values.toList(),
          locationAvailable: state.locationAvailable,
          isStaleFallback: result.isStaleFallback,
        ),
        allSites: mergedById.values.toList(),
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor?.isNotEmpty ?? false,
        loadMoreFailed: false,
        clearLoadMoreError: true,
        isLoadingMore: false,
        feedVariant: result.feedVariant,
        servedFromCache: result.servedFromCache,
        isStaleFallback: result.isStaleFallback,
        cachedAt: result.cachedAt,
        lastSuccessfulRefreshAt: result.servedFromCache
            ? state.lastSuccessfulRefreshAt
            : DateTime.now(),
      );
      return true;
    } on AppError catch (e) {
      state = state.copyWith(
        status: FeedSitesViewStatus.paginationError,
        loadMoreFailed: true,
        loadMoreError: e,
        isLoadingMore: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: FeedSitesViewStatus.paginationError,
        loadMoreFailed: true,
        loadMoreError: AppError.network(cause: e),
        isLoadingMore: false,
      );
      return false;
    }
  }

  void removeSite(String siteId) {
    state = state.copyWith(
      allSites: state.allSites.where((PollutionSite s) => s.id != siteId).toList(),
    );
  }

  /// Keeps [PollutionSite.isSavedByMe] in sync with [SiteEngagementNotifier] so the
  /// client-side [FeedFilter.saved] tab matches the bookmark affordance.
  void patchSiteSaved(String siteId, bool isSavedByMe) {
    state = state.copyWith(
      allSites: patchPollutionSitesSavedFlag(state.allSites, siteId, isSavedByMe),
    );
  }

  /// Keeps [PollutionSite.commentsCount] in sync after comments sheet loads or mutates,
  /// so [PollutionSite.commentCount] / engagement hydrate match server state.
  void patchSiteCommentsCount(String siteId, int commentsCount) {
    state = state.copyWith(
      allSites: patchPollutionSitesCommentsCount(state.allSites, siteId, commentsCount),
    );
  }

  Future<void> _resolveUserLocation() async {
    bool locationAvailable = true;
    double? lat;
    double? lng;
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationAvailable = false;
        lat = null;
        lng = null;
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          locationAvailable = false;
          lat = null;
          lng = null;
        } else {
          try {
            final Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 12),
            );
            lat = position.latitude;
            lng = position.longitude;
            locationAvailable = true;
          } on Object catch (_) {
            final Position? last = await Geolocator.getLastKnownPosition();
            if (last != null) {
              lat = last.latitude;
              lng = last.longitude;
              locationAvailable = true;
            } else {
              locationAvailable = false;
            }
          }
        }
      }
    } catch (_) {
      locationAvailable = false;
      lat = null;
      lng = null;
    }
    state = FeedSitesState(
      allSites: state.allSites,
      status: state.status,
      isLoading: state.isLoading,
      loadError: state.loadError,
      nextCursor: state.nextCursor,
      hasMore: state.hasMore,
      isLoadingMore: state.isLoadingMore,
      loadMoreFailed: state.loadMoreFailed,
      locationAvailable: locationAvailable,
      userLatitude: lat,
      userLongitude: lng,
      feedVariant: state.feedVariant,
      servedFromCache: state.servedFromCache,
      isStaleFallback: state.isStaleFallback,
      cachedAt: state.cachedAt,
      lastSuccessfulRefreshAt: state.lastSuccessfulRefreshAt,
    );
  }
}

final feedVisibleSitesProvider = Provider<List<PollutionSite>>((Ref ref) {
  final FeedSitesState sites = ref.watch(feedSitesNotifierProvider);
  final FeedFilter filter = ref.watch(feedFilterProvider);
  return computeVisibleSitesForFilter(
    source: sites.allSites,
    filter: filter,
    feedVariant: sites.feedVariant,
  );
});
