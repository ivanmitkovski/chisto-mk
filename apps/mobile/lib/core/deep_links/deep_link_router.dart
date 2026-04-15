import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';

/// Parsed in-app route from a universal / custom-scheme link.
sealed class DeepLinkRoute {
  const DeepLinkRoute();
}

final class DeepLinkEventDetail extends DeepLinkRoute {
  const DeepLinkEventDetail(this.eventId);

  final String eventId;
}

final class DeepLinkNewReport extends DeepLinkRoute {
  const DeepLinkNewReport();
}

final class DeepLinkHomeMapFocus extends DeepLinkRoute {
  const DeepLinkHomeMapFocus(this.siteId);

  final String siteId;
}

final class DeepLinkHomeEvents extends DeepLinkRoute {
  const DeepLinkHomeEvents();
}

/// Maps `https://chisto.mk/app/...`, `chisto://app/...`, and path-only variants to [AppRoutes].
class DeepLinkRouter {
  DeepLinkRouter._();

  /// Returns a route plan when the URI is recognized; otherwise `null`.
  static DeepLinkRoute? parse(Uri uri) {
    final List<String> raw = uri.pathSegments.where((String s) => s.isNotEmpty).toList();
    final List<String> seg = raw.isNotEmpty && raw.first == 'app' ? raw.sublist(1) : raw;

    if (seg.length >= 3 && seg[0] == 'events' && seg[1] == 'detail') {
      final String id = seg[2].trim();
      if (id.isEmpty) return null;
      return DeepLinkEventDetail(id);
    }
    if (seg.length >= 2 && seg[0] == 'events' && seg[1] == 'detail') {
      final String? id = uri.queryParameters['eventId'] ?? uri.queryParameters['id'];
      if (id == null || id.trim().isEmpty) return null;
      return DeepLinkEventDetail(id.trim());
    }
    if (seg.length >= 2 && seg[0] == 'reports' && seg[1] == 'new') {
      return const DeepLinkNewReport();
    }
    if (seg.length >= 2 && seg[0] == 'home' && seg[1] == 'map-focus') {
      final String? siteId =
          uri.queryParameters['siteId']?.trim() ?? (seg.length > 2 ? seg[2].trim() : null);
      if (siteId == null || siteId.isEmpty) return null;
      return DeepLinkHomeMapFocus(siteId);
    }
    if (seg.length == 1 && seg[0] == 'home' && uri.queryParameters['tab'] == 'events') {
      return const DeepLinkHomeEvents();
    }
    return null;
  }

  /// Applies [parse] and pushes a named route when recognized.
  ///
  /// Event list/detail deep links require a signed-in session (API is JWT-only).
  static bool handleUri(
    NavigatorState nav,
    Uri uri, {
    required bool isAuthenticated,
  }) {
    final DeepLinkRoute? route = parse(uri);
    switch (route) {
      case DeepLinkEventDetail(:final String eventId):
        if (!isAuthenticated) {
          nav.pushNamed(AppRoutes.signIn);
          return true;
        }
        nav.pushNamed(
          AppRoutes.eventsDetail,
          arguments: EventRouteArguments(eventId: eventId),
        );
        return true;
      case DeepLinkNewReport():
        nav.pushNamed(AppRoutes.newReport);
        return true;
      case DeepLinkHomeMapFocus(:final String siteId):
        nav.pushNamed(
          AppRoutes.homeMapFocus,
          arguments: MapSiteFocusRouteArgs(siteId: siteId),
        );
        return true;
      case DeepLinkHomeEvents():
        if (!isAuthenticated) {
          nav.pushNamed(AppRoutes.signIn);
          return true;
        }
        nav.pushNamed(AppRoutes.homeEvents);
        return true;
      case null:
        return false;
    }
  }
}
