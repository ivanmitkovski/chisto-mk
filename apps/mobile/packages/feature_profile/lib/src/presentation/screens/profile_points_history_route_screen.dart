import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/presentation/providers/profile_providers.dart';
import 'package:feature_profile/src/presentation/screens/profile_points_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root-stack profile points history (achievement notifications).
class ProfilePointsHistoryRouteScreen extends ConsumerStatefulWidget {
  const ProfilePointsHistoryRouteScreen({super.key, this.summaryUser});

  final ProfileUser? summaryUser;

  @override
  ConsumerState<ProfilePointsHistoryRouteScreen> createState() =>
      _ProfilePointsHistoryRouteScreenState();
}

class _ProfilePointsHistoryRouteScreenState
    extends ConsumerState<ProfilePointsHistoryRouteScreen> {
  Future<ProfileUser?>? _userFuture;

  @override
  void initState() {
    super.initState();
    if (widget.summaryUser != null) {
      _userFuture = Future<ProfileUser?>.value(widget.summaryUser);
    } else {
      _userFuture = ref.read(profileRepositoryProvider).getMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileUser?>(
      future: _userFuture,
      builder: (BuildContext context, AsyncSnapshot<ProfileUser?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: AppLoadingIndicator()),
          );
        }
        if (snapshot.hasError) {
          final Object err = snapshot.error!;
          final AppError appError =
              err is AppError ? err : AppError.unknown(cause: err);
          return Scaffold(
            body: AppErrorView(
              error: appError,
              onRetry: () {
                setState(() {
                  _userFuture = ref.read(profileRepositoryProvider).getMe();
                });
              },
            ),
          );
        }
        final ProfileUser? user = snapshot.data;
        if (user == null) {
          return Scaffold(
            body: AppEmptyState(
              icon: Icons.person_outline_rounded,
              title: context.l10n.profileErrorSemantic,
              action: AppButton.outlined(
                label: context.l10n.commonRetry,
                onPressed: () {
                  setState(() {
                    _userFuture = ref.read(profileRepositoryProvider).getMe();
                  });
                },
              ),
            ),
          );
        }
        return ProfilePointsHistoryScreen(summaryUser: user);
      },
    );
  }
}

ProfilePointsHistoryRouteExtra? profilePointsHistoryExtraFrom(Object? extra) {
  if (extra is ProfilePointsHistoryRouteExtra) {
    return extra;
  }
  if (extra is ProfileUser) {
    return ProfilePointsHistoryRouteExtra(summaryUser: extra);
  }
  return null;
}
