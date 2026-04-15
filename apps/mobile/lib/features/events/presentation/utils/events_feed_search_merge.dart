import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';

/// Merges the advanced filter sheet with top [EcoEventFilter] pills for `/events` queries.
///
/// See [events_presentation_conventions.dart] for the full feed filtering model.
class EventsFeedSearchMerge {
  const EventsFeedSearchMerge._();

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
