import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';

/// Immutable discovery feed UI state for [EventsFeedController].
class EventsFeedState {
  const EventsFeedState({
    this.activeFilter = EcoEventFilter.all,
    this.activeSearchParams = const EcoEventSearchParams(),
    this.searchQuery = '',
    this.calendarView = false,
    this.recentSearches = const <String>[],
    this.isInitialLoading = true,
    this.initialLoadError,
    this.lastPullRefreshError,
    this.userLatitude,
    this.userLongitude,
    this.repositoryEpoch = 0,
  });

  final EcoEventFilter activeFilter;
  final EcoEventSearchParams activeSearchParams;
  final String searchQuery;
  final bool calendarView;
  final List<String> recentSearches;
  final bool isInitialLoading;
  final AppError? initialLoadError;
  final AppError? lastPullRefreshError;
  final double? userLatitude;
  final double? userLongitude;

  /// Bumped when [EventsRepository] notifies so watchers rebuild list data.
  final int repositoryEpoch;

  EventsFeedState copyWith({
    EcoEventFilter? activeFilter,
    EcoEventSearchParams? activeSearchParams,
    String? searchQuery,
    bool? calendarView,
    List<String>? recentSearches,
    bool? isInitialLoading,
    AppError? initialLoadError,
    bool clearInitialLoadError = false,
    AppError? lastPullRefreshError,
    bool clearLastPullRefreshError = false,
    double? userLatitude,
    double? userLongitude,
    bool clearUserLocation = false,
    int? repositoryEpoch,
  }) {
    return EventsFeedState(
      activeFilter: activeFilter ?? this.activeFilter,
      activeSearchParams: activeSearchParams ?? this.activeSearchParams,
      searchQuery: searchQuery ?? this.searchQuery,
      calendarView: calendarView ?? this.calendarView,
      recentSearches: recentSearches ?? this.recentSearches,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      initialLoadError: clearInitialLoadError
          ? null
          : (initialLoadError ?? this.initialLoadError),
      lastPullRefreshError: clearLastPullRefreshError
          ? null
          : (lastPullRefreshError ?? this.lastPullRefreshError),
      userLatitude: clearUserLocation
          ? null
          : (userLatitude ?? this.userLatitude),
      userLongitude: clearUserLocation
          ? null
          : (userLongitude ?? this.userLongitude),
      repositoryEpoch: repositoryEpoch ?? this.repositoryEpoch,
    );
  }
}
