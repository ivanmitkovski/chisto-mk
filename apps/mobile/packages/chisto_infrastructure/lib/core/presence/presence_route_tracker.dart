import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/presence/presence_service.dart';
import 'package:go_router/go_router.dart';

/// Tracks the current route for presence heartbeats.
void bindPresenceRouteTracker(GoRouter router) {
  void sync() {
    final String path = router.routeInformationProvider.value.uri.path;
    globalPresenceService?.setScreenFromPath(path);
  }

  router.routeInformationProvider.addListener(sync);
  sync();
}

void bindPresenceRouteTrackerFromAppRouter() {
  bindPresenceRouteTracker(appGoRouter);
}
