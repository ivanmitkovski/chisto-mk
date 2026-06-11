import 'dart:async';

import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_auth/src/presentation/utils/auth_guard_ui.dart';
import 'package:feature_notifications/src/data/notification_open_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Parsed in-app route from a universal / custom-scheme link.
sealed class DeepLinkRoute {
  const DeepLinkRoute();

  /// Optional share-attribution token (`?st=`) carried by public share links.
  String? get shareToken => null;

  /// Optional campaign id (`?cid=`) carried by public share links.
  String? get cid => null;
}

final class DeepLinkEventDetail extends DeepLinkRoute {
  const DeepLinkEventDetail(this.eventId);

  final String eventId;
}

final class DeepLinkNewReport extends DeepLinkRoute {
  const DeepLinkNewReport();
}

final class DeepLinkHomeMapFocus extends DeepLinkRoute {
  const DeepLinkHomeMapFocus(this.siteId, {this.shareToken, this.cid});

  final String siteId;
  @override
  final String? shareToken;
  @override
  final String? cid;
}

final class DeepLinkHomeEvents extends DeepLinkRoute {
  const DeepLinkHomeEvents();
}

/// Public share URL: `https://chisto.mk/sites/<id>` opens the site detail screen.
final class DeepLinkSiteDetail extends DeepLinkRoute {
  const DeepLinkSiteDetail(this.siteId, {this.shareToken, this.cid});

  final String siteId;
  @override
  final String? shareToken;
  @override
  final String? cid;
}

/// Prisma `cuid()` pattern used by current Site ids.
final RegExp _cuidPattern = RegExp(r'^c[a-z0-9]{24}$', caseSensitive: false);

/// Hosts allowed for `https://…/events/<id>` share links (avoid open redirects).
bool deepLinkTrustedShareHost(String? host) {
  final String h = (host ?? '').toLowerCase();
  if (h.isEmpty) {
    return true;
  }
  if (h == 'chisto.mk' || h == 'www.chisto.mk') {
    return true;
  }
  if (h == 'localhost' || h == '127.0.0.1') {
    return true;
  }
  if (h.endsWith('.chisto.mk')) {
    return true;
  }
  return false;
}

/// Maps `https://chisto.mk/app/...`, `chisto://app/...`, and path-only variants to [AppRoutes].
class DeepLinkRouter {
  DeepLinkRouter._();

  static String? _lastHandledUri;
  static DateTime? _lastHandledAt;
  static const Duration _dedupeWindow = Duration(seconds: 5);

  static void resetDedupeForTest() {
    _lastHandledUri = null;
    _lastHandledAt = null;
    _pendingAuthenticatedUri = null;
  }

  static Uri? _pendingAuthenticatedUri;

  @visibleForTesting
  static Uri? get pendingAuthenticatedUriForTest => _pendingAuthenticatedUri;

  // ignore: use_setters_to_change_properties, command-style router API paired with clearPendingAuthenticatedUri
  static void queuePendingAuthenticatedUri(Uri uri) {
    _pendingAuthenticatedUri = uri;
  }

  static void clearPendingAuthenticatedUri() {
    _pendingAuthenticatedUri = null;
  }

  static bool replayPendingAuthenticatedRoute(GoRouter router) {
    final Uri? uri = _pendingAuthenticatedUri;
    if (uri == null) return false;
    _pendingAuthenticatedUri = null;
    _lastHandledUri = null;
    _lastHandledAt = null;
    return handleUri(router, uri, isAuthenticated: true);
  }

  /// Like [handleUri] but runs async location gating for point-giving deep links when [context] is available.
  static Future<bool> handleUriAsync(
    GoRouter router,
    Uri uri, {
    required bool isAuthenticated,
    BuildContext? context,
  }) async {
    if (_isDuplicate(uri)) {
      return true;
    }
    final DeepLinkRoute? route = parse(uri);
    switch (route) {
      case DeepLinkNewReport():
        _markHandled(uri);
        if (!isAuthenticated) {
          queuePendingAuthenticatedUri(uri);
          AppNavigation.goSignIn();
          return true;
        }
        if (context != null && context.mounted) {
          final ProviderContainer container = ProviderScope.containerOf(
            context,
          );
          if (!await ensureLocationEligibleForActionWithRead(
            context,
            container.read,
          )) {
            return true;
          }
        } else {
          await AppNavigation.pushNewReport();
        }
        return true;
      default:
        return handleUri(router, uri, isAuthenticated: isAuthenticated);
    }
  }

  static DeepLinkRoute? parse(Uri uri) {
    final List<String> raw = uri.pathSegments
        .where((String s) => s.isNotEmpty)
        .toList();

    if (raw.length == 2 && raw[0] == 'sites') {
      final String id = raw[1].trim();
      if (id.isNotEmpty &&
          _cuidPattern.hasMatch(id) &&
          deepLinkTrustedShareHost(uri.host)) {
        final String? st = uri.queryParameters['st']?.trim();
        final String? cid = uri.queryParameters['cid']?.trim();
        return DeepLinkSiteDetail(
          id,
          shareToken: st != null && st.isNotEmpty ? st : null,
          cid: cid != null && cid.isNotEmpty ? cid : null,
        );
      }
    }

    if (raw.length == 2 && raw[0] == 'events') {
      final String id = raw[1].trim();
      if (id.isNotEmpty &&
          notificationOpenPayloadLooksLikeEventId(id) &&
          deepLinkTrustedShareHost(uri.host)) {
        return DeepLinkEventDetail(id);
      }
    }

    final List<String> seg = raw.isNotEmpty && raw.first == 'app'
        ? raw.sublist(1)
        : raw;

    if (seg.length >= 3 && seg[0] == 'events' && seg[1] == 'detail') {
      final String id = seg[2].trim();
      if (id.isEmpty || !notificationOpenPayloadLooksLikeEventId(id)) {
        return null;
      }
      return DeepLinkEventDetail(id);
    }
    if (seg.length >= 2 && seg[0] == 'events' && seg[1] == 'detail') {
      final String? id =
          uri.queryParameters['eventId'] ?? uri.queryParameters['id'];
      if (id == null ||
          id.trim().isEmpty ||
          !notificationOpenPayloadLooksLikeEventId(id.trim())) {
        return null;
      }
      return DeepLinkEventDetail(id.trim());
    }
    if (seg.length >= 2 && seg[0] == 'reports' && seg[1] == 'new') {
      return const DeepLinkNewReport();
    }
    if (seg.length >= 2 && seg[0] == 'home' && seg[1] == 'map-focus') {
      final String? siteId =
          uri.queryParameters['siteId']?.trim() ??
          (seg.length > 2 ? seg[2].trim() : null);
      if (siteId == null || siteId.isEmpty) return null;
      final String? st = uri.queryParameters['st']?.trim();
      final String? cid = uri.queryParameters['cid']?.trim();
      return DeepLinkHomeMapFocus(
        siteId,
        shareToken: st != null && st.isNotEmpty ? st : null,
        cid: cid != null && cid.isNotEmpty ? cid : null,
      );
    }
    if (seg.length == 1 &&
        seg[0] == 'home' &&
        uri.queryParameters['tab'] == 'events') {
      return const DeepLinkHomeEvents();
    }
    return null;
  }

  static bool handleUri(
    GoRouter router,
    Uri uri, {
    required bool isAuthenticated,
  }) {
    if (_isDuplicate(uri)) {
      return true;
    }
    final DeepLinkRoute? route = parse(uri);
    switch (route) {
      case DeepLinkEventDetail(:final String eventId):
        _markHandled(uri);
        if (!isAuthenticated) {
          queuePendingAuthenticatedUri(uri);
          AppNavigation.goSignIn();
          return true;
        }
        AppNavigation.pushEventDetail(eventId: eventId);
        return true;
      case DeepLinkNewReport():
        _markHandled(uri);
        if (!isAuthenticated) {
          queuePendingAuthenticatedUri(uri);
          AppNavigation.goSignIn();
          return true;
        }
        unawaited(AppNavigation.pushNewReport());
        return true;
      case DeepLinkHomeMapFocus(:final String siteId):
        _markHandled(uri);
        if (!isAuthenticated) {
          queuePendingAuthenticatedUri(uri);
          AppNavigation.goSignIn();
          return true;
        }
        AppNavigation.navigateToHomeMapFocus(
          args: MapSiteFocusRouteArgs(siteId: siteId),
        );
        return true;
      case DeepLinkSiteDetail(:final String siteId):
        _markHandled(uri);
        if (!isAuthenticated) {
          queuePendingAuthenticatedUri(uri);
          AppNavigation.goSignIn();
          return true;
        }
        AppNavigation.pushSiteDetail(SiteDetailByIdRouteArgs(siteId: siteId));
        return true;
      case DeepLinkHomeEvents():
        _markHandled(uri);
        if (!isAuthenticated) {
          queuePendingAuthenticatedUri(uri);
          AppNavigation.goSignIn();
          return true;
        }
        AppNavigation.navigateToHomeEvents();
        return true;
      case null:
        return false;
    }
  }

  static bool _isDuplicate(Uri uri) {
    final String key = uri.toString();
    final String? prev = _lastHandledUri;
    final DateTime? at = _lastHandledAt;
    if (prev == null || at == null || prev != key) {
      return false;
    }
    return DateTime.now().difference(at) < _dedupeWindow;
  }

  static void _markHandled(Uri uri) {
    _lastHandledUri = uri.toString();
    _lastHandledAt = DateTime.now();
  }
}
