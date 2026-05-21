export 'package:chisto_mobile/core/providers/refresh_signals_providers.dart'
    show eventsFeedRefreshTickProvider;

import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/features/events/data/api_event_analytics_repository.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).eventsRepository;
});

final checkInRepositoryProvider = Provider<CheckInRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).checkInRepository;
});

final eventChatRepositoryProvider = Provider<EventChatRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).eventChatRepository;
});

final eventAnalyticsRepositoryProvider =
    Provider<ApiEventAnalyticsRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).eventAnalyticsRepository;
});
