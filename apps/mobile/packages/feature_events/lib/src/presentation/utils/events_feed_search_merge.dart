import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';

/// Merges the advanced filter sheet with top [EcoEventFilter] pills for `/events` queries.
///
/// Chip filters split into **server fetch groups** (mirrors home [feedServerFetchGroup]):
/// instant client-side switches within a group; background `/events` refresh only when
/// the group changes.
class EventsFeedSearchMerge {
  const EventsFeedSearchMerge._();

  /// Identity for server list pagination/cache. Filters in the same group share one
  /// in-memory snapshot and switch instantly without a network round-trip.
  static int serverFetchGroup(EcoEventFilter chip) {
    switch (chip) {
      case EcoEventFilter.all:
      case EcoEventFilter.nearby:
      case EcoEventFilter.myEvents:
        return 0;
      case EcoEventFilter.upcoming:
        return 1;
      case EcoEventFilter.past:
        return 2;
    }
  }

  /// Refines an in-memory list for chip tabs before/while a server fetch runs.
  static List<EcoEvent> applyChipClientFilter(
    List<EcoEvent> source,
    EcoEventFilter chip, {
    required bool Function(EcoEvent event) visibleInPublicDiscovery,
  }) {
    switch (chip) {
      case EcoEventFilter.all:
      case EcoEventFilter.nearby:
      case EcoEventFilter.myEvents:
        return source;
      case EcoEventFilter.upcoming:
        return source
            .where(
              (EcoEvent e) =>
                  e.status == EcoEventStatus.upcoming ||
                  e.status == EcoEventStatus.inProgress,
            )
            .where(visibleInPublicDiscovery)
            .toList();
      case EcoEventFilter.past:
        return source
            .where((EcoEvent e) => e.isPastForPublicDiscovery)
            .toList();
    }
  }

  /// **Upcoming** / **Past** pills override lifecycle filters from the sheet for the
  /// server request (chip wins). **Nearby** and **My events** do not change the query;
  /// they only affect client-side ordering / filtering on [EventsFeedScreen].
  static EcoEventSearchParams mergedForChip(
    EcoEventSearchParams sheet,
    EcoEventFilter chip,
  ) {
    switch (chip) {
      case EcoEventFilter.upcoming:
        return sheet.copyWith(
          statuses: <EcoEventStatus>{EcoEventStatus.upcoming},
        );
      case EcoEventFilter.past:
        return sheet.copyWith(
          statuses: <EcoEventStatus>{
            EcoEventStatus.completed,
            EcoEventStatus.cancelled,
          },
        );
      case EcoEventFilter.all:
      case EcoEventFilter.nearby:
      case EcoEventFilter.myEvents:
        return sheet;
    }
  }
}
