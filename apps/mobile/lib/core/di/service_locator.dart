import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/data/in_memory_check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final AppConfig config;
  late final AuthState authState;
  late final EventsRepository eventsRepository;
  late final CheckInRepository checkInRepository;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  void initialize({AppConfig? config}) {
    if (_initialized) return;

    this.config = config ?? AppConfig.fromEnvironment();
    authState = AuthState();

    eventsRepository = InMemoryEventsStore.instance;
    checkInRepository = InMemoryCheckInRepository.instance;

    authState.setAuthenticated(
      userId: 'current_user',
      displayName: 'You',
    );

    _initialized = true;
  }

  void reset() {
    _initialized = false;
  }
}
