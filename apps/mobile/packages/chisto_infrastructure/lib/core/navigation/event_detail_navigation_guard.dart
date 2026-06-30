import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:flutter/foundation.dart';

/// Single-top and in-flight coalescing for event detail navigation.
abstract final class EventDetailNavigationGuard {
  const EventDetailNavigationGuard._();

  static final Map<String, Future<void>> _inFlightByEventId =
      <String, Future<void>>{};

  @visibleForTesting
  static void resetForTest() {
    _inFlightByEventId.clear();
  }

  static String eventDetailPath(String eventId) {
    return '${AppRoutes.eventsDetail}/${eventId.trim()}';
  }

  static bool isEventDetailTopRoute(String eventId) {
    final String id = eventId.trim();
    if (id.isEmpty) {
      return false;
    }
    try {
      final String path = appGoRouter.routeInformationProvider.value.uri.path;
      return path == eventDetailPath(id);
    } on Object {
      return false;
    }
  }

  /// Runs [push] at most once per [eventId] while a navigation is in flight.
  ///
  /// Skips when the same event detail is already the top route.
  static Future<void> coalescedPush(
    String eventId,
    Future<void> Function() push,
  ) {
    final String id = eventId.trim();
    if (id.isEmpty) {
      return Future<void>.value();
    }
    if (isEventDetailTopRoute(id)) {
      return Future<void>.value();
    }

    return _inFlightByEventId.putIfAbsent(id, () async {
      try {
        if (isEventDetailTopRoute(id)) {
          return;
        }
        await push();
      } finally {
        _inFlightByEventId.remove(id);
      }
    });
  }
}
