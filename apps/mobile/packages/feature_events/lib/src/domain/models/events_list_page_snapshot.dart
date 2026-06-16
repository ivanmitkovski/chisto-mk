import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:meta/meta.dart';

/// First-page result for filter preview (count + pagination hint).
@immutable
class EventsListPageSnapshot {
  const EventsListPageSnapshot({required this.events, required this.hasMore});

  final List<EcoEvent> events;
  final bool hasMore;

  int get count => events.length;
}
