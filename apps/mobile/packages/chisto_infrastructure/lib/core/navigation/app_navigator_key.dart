import 'package:flutter/material.dart';

/// Root [NavigatorState] for [MaterialApp] (deep links, push notification opens).
final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'appRootNavigator',
);

/// Reserved for transitional nested-shell experiments; feed full-screen routes use
/// [appRootNavigatorKey] as [GoRoute.parentNavigatorKey] on the root [GoRouter].
final GlobalKey<NavigatorState> homeShellGoRouterNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'homeShellGoRouterRoot');
