export 'package:chisto_mobile/core/providers/refresh_signals_providers.dart'
    show
        notificationsInboxRefreshTickProvider,
        notificationsUnreadCountProvider;

import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_realtime_service.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_store.dart';
import 'package:chisto_mobile/features/notifications/data/notifications_inbox_coordinator.dart';
import 'package:chisto_mobile/features/notifications/data/notifications_realtime_service.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapRealtimeServiceProvider = Provider<MapRealtimeService>((Ref ref) {
  return ref.watch(appBootstrapProvider).mapRealtimeService;
});

final offlineRegionStoreProvider = Provider<OfflineRegionStore>((Ref ref) {
  return ref.watch(appBootstrapProvider).offlineRegionStore;
});

final notificationsInboxCoordinatorProvider =
    Provider<NotificationsInboxCoordinator>((Ref ref) {
  return ref.watch(appBootstrapProvider).notificationsInboxCoordinator;
});

final notificationsRealtimeServiceProvider =
    Provider<NotificationsRealtimeService>((Ref ref) {
  return ref.watch(appBootstrapProvider).notificationsRealtimeService;
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((Ref ref) {
  return ref.watch(appBootstrapProvider).pushNotificationService;
});
