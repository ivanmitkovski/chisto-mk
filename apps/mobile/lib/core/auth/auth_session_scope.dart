import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/navigation/app_navigator_key.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/core/providers/notifications_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';

/// Navigates to sign-in when the session becomes unauthenticated outside explicit sign-out.
class AuthSessionScope extends StatefulWidget {
  const AuthSessionScope({super.key, required this.child});

  final Widget child;

  @override
  State<AuthSessionScope> createState() => _AuthSessionScopeState();
}

class _AuthSessionScopeState extends State<AuthSessionScope> {
  AuthStatus? _previousStatus;
  bool _explicitSignOut = false;
  bool _sessionLossNavigationInFlight = false;

  static const Set<String> _authGateRoutes = <String>{
    AppRoutes.splash,
    AppRoutes.initialRoute,
    AppRoutes.onboarding,
    AppRoutes.signIn,
  };

  AppBootstrap get _bootstrap => readRoot(appBootstrapProvider);

  AuthState get _authState => readRoot(authStateProvider);

  @override
  void initState() {
    super.initState();
    _previousStatus = _authState.status;
    if (_previousStatus == AuthStatus.authenticated) {
      readRoot(notificationsRealtimeServiceProvider).start();
    }
    _authState.addListener(_onAuthChanged);
    _bootstrap.onAuthUnauthorized = _handleUnauthorized;
    _bootstrap.onExplicitSignOut = () => _explicitSignOut = true;
  }

  @override
  void dispose() {
    _authState.removeListener(_onAuthChanged);
    _bootstrap.onAuthUnauthorized = null;
    _bootstrap.onExplicitSignOut = null;
    super.dispose();
  }

  void _handleUnauthorized() {
    if (_explicitSignOut) return;
    _handleSessionLoss();
  }

  void _onAuthChanged() {
    final AuthStatus current = _authState.status;
    final AuthStatus? previous = _previousStatus;
    _previousStatus = current;

    if (previous == AuthStatus.authenticated &&
        current == AuthStatus.unauthenticated &&
        !_explicitSignOut) {
      _handleSessionLoss();
    }
    if (current == AuthStatus.authenticated) {
      _explicitSignOut = false;
      _sessionLossNavigationInFlight = false;
    } else if (previous == AuthStatus.authenticated) {
      readRoot(notificationsRealtimeServiceProvider).stop();
    }
  }

  void _handleSessionLoss() {
    if (_sessionLossNavigationInFlight) {
      return;
    }
    if (_isOnAuthGateRoute()) {
      return;
    }
    _sessionLossNavigationInFlight = true;
    _navigateToSignIn(showExpiredMessage: _shouldShowSessionExpiredMessage());
  }

  bool _shouldShowSessionExpiredMessage() {
    if (_bootstrap.shouldSuppressSessionExpiredMessage()) {
      return false;
    }
    if (_isOnAuthGateRoute()) {
      return false;
    }
    return true;
  }

  String? _topRouteName() {
    final NavigatorState? nav = appRootNavigatorKey.currentState;
    if (nav == null) {
      return null;
    }
    String? name;
    nav.popUntil((Route<dynamic> route) {
      name = route.settings.name;
      return true;
    });
    return name;
  }

  bool _isOnAuthGateRoute() {
    final String? name = _topRouteName();
    return name != null && _authGateRoutes.contains(name);
  }

  void _navigateToSignIn({required bool showExpiredMessage}) {
    final NavigatorState? nav = appRootNavigatorKey.currentState;
    if (nav == null) return;
    if (!_isOnAuthGateRoute()) {
      nav.pushNamedAndRemoveUntil(AppRoutes.signIn, (Route<dynamic> r) => false);
    }
    if (!showExpiredMessage) return;
    final BuildContext? ctx = appRootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    AppSnack.show(
      ctx,
      message: AppLocalizations.of(ctx)!.authSessionExpired,
      type: AppSnackType.warning,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
