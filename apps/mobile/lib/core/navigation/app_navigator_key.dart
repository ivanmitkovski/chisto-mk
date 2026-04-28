import 'package:flutter/material.dart';

/// Root [NavigatorState] for [MaterialApp] (deep links, push notification opens).
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appRootNavigator');

/// Root navigator for the nested home [GoRouter]. Full-screen shell routes must
/// use this as [GoRoute.parentNavigatorKey]; it cannot be [appRootNavigatorKey]
/// because that key is already bound to [MaterialApp]'s navigator.
final GlobalKey<NavigatorState> homeShellGoRouterNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'homeShellGoRouterRoot');
