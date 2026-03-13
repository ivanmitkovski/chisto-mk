import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';

class EventsRepositoryRegistry {
  const EventsRepositoryRegistry._();

  static final EventsRepository instance = InMemoryEventsStore.instance;
}
