import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:flutter/foundation.dart';

class EventsRepositoryRegistry {
  const EventsRepositoryRegistry._();

  static EventsRepository? _testOverride;

  /// Widget / integration tests can pin an in-memory store without booting [AppBootstrap].
  @visibleForTesting
  static void setTestOverride(EventsRepository? repository) {
    _testOverride = repository;
  }

  static EventsRepository get instance =>
      _testOverride ?? AppBootstrap.instance.eventsRepository;
}
