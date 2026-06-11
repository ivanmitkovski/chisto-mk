import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/presentation/screens/profile_points_history_screen.dart';
import 'package:flutter/material.dart';

/// Root-stack profile points history (achievement notifications).
class ProfilePointsHistoryRouteScreen extends StatefulWidget {
  const ProfilePointsHistoryRouteScreen({super.key, this.summaryUser});

  final ProfileUser? summaryUser;

  @override
  State<ProfilePointsHistoryRouteScreen> createState() =>
      _ProfilePointsHistoryRouteScreenState();
}

class _ProfilePointsHistoryRouteScreenState
    extends State<ProfilePointsHistoryRouteScreen> {
  Future<ProfileUser?>? _userFuture;

  @override
  void initState() {
    super.initState();
    if (widget.summaryUser != null) {
      _userFuture = Future<ProfileUser?>.value(widget.summaryUser);
    } else {
      _userFuture = AppBootstrap.instance.profileRepository.getMe();
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
        final ProfileUser? user = snapshot.data;
        if (user == null) {
          return const Scaffold(body: SizedBox.shrink());
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
