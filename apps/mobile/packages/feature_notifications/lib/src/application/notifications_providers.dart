import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_notifications/src/data/notifications_inbox_coordinator.dart';
import 'package:feature_notifications/src/data/notifications_realtime_service.dart';
import 'package:feature_notifications/src/data/push_notification_service.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart'
    show
        notificationsInboxRefreshTickProvider,
        notificationsUnreadCountProvider;

final mapRealtimeServiceProvider = Provider<MapRealtimeService>((Ref ref) {
  return ref.watch(appBootstrapProvider).mapRealtimeService;
});

final notificationsInboxCoordinatorProvider =
    Provider<NotificationsInboxCoordinator>((Ref ref) {
      return ref.watch(appBootstrapProvider).notificationsInboxCoordinator;
    });

final notificationsRealtimeServiceProvider =
    Provider<NotificationsRealtimeService>((Ref ref) {
      return ref.watch(appBootstrapProvider).notificationsRealtimeService;
    });

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).pushNotificationService;
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).notificationsRepository;
});
