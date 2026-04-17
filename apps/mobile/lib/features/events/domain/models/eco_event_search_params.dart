import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Parameters driving the server-side events list query.
///
/// Passed to [EventsRepository.refreshEvents] / [ApiEventsRepository._fetchPage]
/// so the feed can request server-filtered results instead of filtering the
/// full in-memory list on the client.
class EcoEventSearchParams {
  const EcoEventSearchParams({
    this.query,
    this.categories = const <EcoEventCategory>{},
    this.statuses = const <EcoEventStatus>{},
    this.dateFrom,
    this.dateTo,
  });

  /// Free-text search string (sent as `q=`). Empty / null → no text filter.
  final String? query;

  /// Category allow-list. Empty → all categories.
  final Set<EcoEventCategory> categories;

  /// Lifecycle status allow-list. Empty → all statuses.
  final Set<EcoEventStatus> statuses;

  /// Inclusive lower bound on event date (sent as `dateFrom=YYYY-MM-DD`).
  final DateTime? dateFrom;

  /// Inclusive upper bound on event date (sent as `dateTo=YYYY-MM-DD`).
  final DateTime? dateTo;

  bool get isEmpty =>
      (query == null || query!.trim().isEmpty) &&
      categories.isEmpty &&
      statuses.isEmpty &&
      dateFrom == null &&
      dateTo == null;

  /// Stable suffix for [EventsLocalCache] keys when this query is non-[isEmpty].
  /// Distinct filter combinations should map to distinct suffixes (collisions only
  /// if [Object.hash] collides for different tuples—vanishingly rare for UI params).
  String get offlineListCacheSuffix {
    final List<String> categoryKeys = categories.map((EcoEventCategory c) => c.key).toList()
      ..sort();
    final List<String> statusKeys = statuses.map((EcoEventStatus s) => s.apiKey).toList()
      ..sort();
    final String q = (query ?? '').trim();
    return 'f${Object.hash(
          q,
          categoryKeys.join(','),
          statusKeys.join(','),
          dateFrom?.millisecondsSinceEpoch,
          dateTo?.millisecondsSinceEpoch,
        ).toUnsigned(32).toRadixString(16)}';
  }

  EcoEventSearchParams copyWith({
    String? query,
    Set<EcoEventCategory>? categories,
    Set<EcoEventStatus>? statuses,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearQuery = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return EcoEventSearchParams(
      query: clearQuery ? null : (query ?? this.query),
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EcoEventSearchParams &&
          other.query == query &&
          _setsEqual(other.categories, categories) &&
          _setsEqual(other.statuses, statuses) &&
          other.dateFrom == dateFrom &&
          other.dateTo == dateTo;

  @override
  int get hashCode => Object.hash(query, categories, statuses, dateFrom, dateTo);

  static bool _setsEqual<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
