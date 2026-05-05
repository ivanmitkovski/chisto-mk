import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/navigation/app_navigator_key.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_avatar_notifier.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Home profile tab: user payload, optional report capacity, load errors.
class ProfileHomeState {
  const ProfileHomeState({
    this.profileLoadError,
    this.profileUser,
    this.reportCapacity,
    this.capacityLoadInFlight = false,
  });

  final AppError? profileLoadError;
  final ProfileUser? profileUser;
  final ReportCapacity? reportCapacity;
  final bool capacityLoadInFlight;
}

final profileHomeNotifierProvider =
    NotifierProvider<ProfileHomeNotifier, ProfileHomeState>(
  ProfileHomeNotifier.new,
);

class ProfileHomeNotifier extends Notifier<ProfileHomeState> {
  static const Duration _minSkeletonDuration = Duration(milliseconds: 400);

  @override
  ProfileHomeState build() => const ProfileHomeState();

  Future<ReportCapacity?> _fetchCapacitySafe() async {
    try {
      return await ref.read(reportsApiRepositoryProvider).getReportingCapacity();
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureMinSkeletonVisible(DateTime loadStarted) async {
    final int elapsed = DateTime.now().difference(loadStarted).inMilliseconds;
    if (elapsed < _minSkeletonDuration.inMilliseconds) {
      await Future<void>.delayed(
        Duration(
          milliseconds: _minSkeletonDuration.inMilliseconds - elapsed,
        ),
      );
    }
  }

  Future<ProfileUser?> _fetchProfileUser() async {
    final authState = ServiceLocator.instance.authState;
    if (!authState.isAuthenticated || authState.userId == null) {
      return null;
    }
    return ref.read(profileRepositoryProvider).getMe();
  }

  static bool _isAuthError(String code) =>
      code == 'UNAUTHORIZED' ||
      code == 'INVALID_TOKEN_USER' ||
      code == 'ACCOUNT_NOT_ACTIVE';

  void _redirectToSignIn() {
    final BuildContext? ctx = appRootNavigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (Route<dynamic> route) => false,
    );
  }

  void _showRefreshFailedSnack() {
    final BuildContext? ctx = appRootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    AppSnack.show(
      ctx,
      message: ctx.l10n.profileRefreshFailedSnack,
      type: AppSnackType.warning,
    );
  }

  Future<void> loadProfile() async {
    final bool hadUser = state.profileUser != null;
    state = ProfileHomeState(
      profileLoadError: null,
      profileUser: state.profileUser,
      reportCapacity: state.reportCapacity,
      capacityLoadInFlight: true,
    );

    final DateTime loadStarted = DateTime.now();
    final Future<ReportCapacity?> capacityFuture = _fetchCapacitySafe();

    try {
      final ProfileUser? loaded = await _fetchProfileUser();
      final ReportCapacity? capacity = await capacityFuture;

      if (!hadUser && loaded != null) {
        await _ensureMinSkeletonVisible(loadStarted);
      }

      final bool authenticated =
          ServiceLocator.instance.authState.isAuthenticated;
      state = ProfileHomeState(
        profileUser: loaded,
        profileLoadError: authenticated && loaded == null
            ? AppError.unknown()
            : null,
        reportCapacity: capacity,
        capacityLoadInFlight: false,
      );
      ref.read(profileAvatarNotifierProvider.notifier).setRemoteUrl(
            loaded?.avatarUrl,
          );
    } on AppError catch (e) {
      await capacityFuture;
      if (_isAuthError(e.code)) {
        state = ProfileHomeState(
          profileLoadError: state.profileLoadError,
          profileUser: state.profileUser,
          reportCapacity: state.reportCapacity,
          capacityLoadInFlight: false,
        );
        _redirectToSignIn();
        return;
      }
      if (hadUser) {
        state = ProfileHomeState(
          profileLoadError: null,
          profileUser: state.profileUser,
          reportCapacity: state.reportCapacity,
          capacityLoadInFlight: false,
        );
        _showRefreshFailedSnack();
      } else {
        state = ProfileHomeState(
          profileLoadError: e,
          profileUser: null,
          reportCapacity: state.reportCapacity,
          capacityLoadInFlight: false,
        );
      }
    } catch (e) {
      await capacityFuture;
      if (hadUser) {
        state = ProfileHomeState(
          profileLoadError: null,
          profileUser: state.profileUser,
          reportCapacity: state.reportCapacity,
          capacityLoadInFlight: false,
        );
        _showRefreshFailedSnack();
      } else {
        state = ProfileHomeState(
          profileLoadError: AppError.network(cause: e),
          profileUser: null,
          reportCapacity: state.reportCapacity,
          capacityLoadInFlight: false,
        );
      }
    }
  }

  void updateUser(ProfileUser user) {
    state = ProfileHomeState(
      profileLoadError: state.profileLoadError,
      profileUser: user,
      reportCapacity: state.reportCapacity,
      capacityLoadInFlight: state.capacityLoadInFlight,
    );
  }
}
