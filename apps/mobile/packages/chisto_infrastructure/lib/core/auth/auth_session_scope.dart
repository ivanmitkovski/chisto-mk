import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
import 'package:flutter/material.dart';

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
    if (previous != AuthStatus.authenticated &&
        current == AuthStatus.authenticated) {
      readRoot(homeShellControllerProvider.notifier).resetTabWidgetKeys();
    } else if (previous == AuthStatus.authenticated &&
        current == AuthStatus.unauthenticated) {
      readRoot(homeShellControllerProvider.notifier).resetTabWidgetKeys();
    }
    if (current == AuthStatus.authenticated) {
      _explicitSignOut = false;
      _sessionLossNavigationInFlight = false;
    } else if (previous == AuthStatus.authenticated) {
      _scheduleAfterFrame(() {
        if (!mounted) return;
        readRoot(notificationsRealtimeServiceProvider).stop();
      });
    }
  }

  void _handleSessionLoss() {
    if (_sessionLossNavigationInFlight) {
      return;
    }
    if (AppNavigation.isOnAuthGateRoute()) {
      return;
    }
    _sessionLossNavigationInFlight = true;
    // Navigation is owned by GoRouter redirect on [AuthState] changes.
    _showSessionExpiredSnackIfNeeded();
  }

  bool _shouldShowSessionExpiredMessage() {
    if (_bootstrap.shouldSuppressSessionExpiredMessage()) {
      return false;
    }
    if (AppNavigation.isOnAuthGateRoute()) {
      return false;
    }
    return true;
  }

  void _showSessionExpiredSnackIfNeeded() {
    if (!_shouldShowSessionExpiredMessage()) {
      return;
    }
    _scheduleAfterFrame(() {
      if (!mounted) return;
      if (AppNavigation.isOnAuthGateRoute()) {
        return;
      }
      final BuildContext? ctx =
          appGoRouter.routerDelegate.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      AppSnack.show(
        ctx,
        message: AppLocalizations.of(ctx)!.authSessionExpired,
        type: AppSnackType.warning,
      );
    });
  }

  void _scheduleAfterFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
