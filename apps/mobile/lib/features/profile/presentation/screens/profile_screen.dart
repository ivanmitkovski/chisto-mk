import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/data/profile_mock_data.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/profile/data/profile_avatar_state.dart';
import 'package:chisto_mobile/features/profile/presentation/navigation/profile_actions_handler.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_general_info_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_password_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/weekly_rankings_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/settings_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isLoadingProfile = true;
  AppError? _profileLoadError;
  ProfileUser? _profileUser;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.emphasizedDuration,
    );
    final authState = ServiceLocator.instance.authState;
    if (authState.isAuthenticated && authState.userId != null) {
      _profileUser = _profileUserFromAuthState();
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _profileLoadError = null;
      _isLoadingProfile = true;
    });
    try {
      final ProfileUser? loaded = await _fetchProfileUser();
      if (!mounted) return;
      setState(() {
        _profileUser = loaded;
        _isLoadingProfile = false;
        _profileLoadError = loaded == null ? AppError.unknown() : null;
      });
      if (loaded != null) _controller.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileLoadError = AppError.network(cause: e);
        _isLoadingProfile = false;
      });
      if (mounted) {
        AppSnack.show(
          context,
          message: 'No connection',
          type: AppSnackType.warning,
        );
      }
    }
  }

  /// Fetches current user from GET /auth/me or builds minimal from auth state.
  Future<ProfileUser?> _fetchProfileUser() async {
    final authState = ServiceLocator.instance.authState;
    if (!authState.isAuthenticated || authState.userId == null) return null;

    try {
      final response = await ServiceLocator.instance.apiClient.get('/auth/me');
      final Map<String, dynamic>? json = response.json;
      if (json == null) return _profileUserFromAuthState();

      final String id = json['id'] as String? ?? authState.userId!;
      final String firstName = json['firstName'] as String? ?? '';
      final String lastName = json['lastName'] as String? ?? '';
      final String name = '$firstName $lastName'.trim();
      final String phoneNumber = (json['phoneNumber'] as String?)?.trim().isNotEmpty == true
          ? (json['phoneNumber'] as String)
          : (authState.phoneNumber ?? '—');
      final int pointsBalance = (json['pointsBalance'] as num?)?.toInt() ?? 0;
      final int level = 1 + (pointsBalance / 100).floor();
      const int pointsToNextLevel = 100;

      return ProfileUser(
        id: id,
        name: name.isEmpty ? (authState.displayName ?? 'User') : name,
        phoneNumber: phoneNumber,
        points: pointsBalance,
        level: level,
        pointsToNextLevel: pointsToNextLevel,
        avatarColor: AppColors.primary,
      );
    } catch (_) {
      return _profileUserFromAuthState();
    }
  }

  ProfileUser _profileUserFromAuthState() {
    final authState = ServiceLocator.instance.authState;
    return ProfileUser(
      id: authState.userId!,
      name: authState.displayName ?? 'User',
      phoneNumber: authState.phoneNumber ?? '—',
      points: 0,
      level: 1,
      pointsToNextLevel: 100,
      avatarColor: AppColors.primary,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_profileLoadError != null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: AppErrorView(
            error: _profileLoadError!,
            onRetry: _loadProfile,
          ),
        ),
      );
    }
    final ProfileUser? loaded = _profileUser;
    if (loaded == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primaryDark,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ),
      );
    }
    final ProfileUser user = loaded;

    final Animation<double> primaryOpacity = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.emphasized,
    );
    final Animation<Offset> levelSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: AppMotion.emphasized),
      ),
    );
    final Animation<Offset> weeklySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: AppMotion.emphasized),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _ProfileHeader(user: user),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.panelBackground,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FadeTransition(
                      opacity: primaryOpacity,
                      child: SlideTransition(
                        position: levelSlide,
                        child: _LevelAndPointsCard(user: user),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeTransition(
                      opacity: primaryOpacity,
                      child: SlideTransition(
                        position: weeklySlide,
                        child: _WeeklyRankCard(
                          points: user.points,
                          onViewRankings: () {
                            AppHaptics.softTransition();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const WeeklyRankingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Account details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(AppSpacing.radius18),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          SettingsListTile(
                            leadingIcon: Icons.person_outline_rounded,
                            title: 'General info',
                            onTap: () {
                              AppHaptics.tap();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProfileGeneralInfoScreen(user: user),
                                ),
                              );
                            },
                            showDividerBelow: true,
                          ),
                          SettingsListTile(
                            leadingIcon: Icons.lock_outline_rounded,
                            title: 'Password',
                            onTap: () {
                              AppHaptics.tap();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ProfilePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Support',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(AppSpacing.radius18),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.9),
                        ),
                      ),
                      child: SettingsListTile(
                        leadingIcon: Icons.help_outline_rounded,
                        title: 'Help center',
                        onTap: () => ProfileActionsHandler.handleHelp(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(AppSpacing.radius18),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          SettingsListTile(
                            leadingIcon: Icons.logout_rounded,
                            title: 'Sign out',
                            onTap: () =>
                                ProfileActionsHandler.handleLogout(context),
                            showTrailingChevron: false,
                            showDividerBelow: true,
                          ),
                          SettingsListTile(
                            leadingIcon: Icons.person_remove_rounded,
                            title: 'Delete account',
                            onTap: () => ProfileActionsHandler.handleDeleteAccount(
                              context,
                            ),
                            isDestructive: true,
                            showTrailingChevron: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                AppBackButton(),
                Spacer(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    AppHaptics.tap();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfileGeneralInfoScreen(user: user),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: profileAvatarState,
                    builder: (BuildContext context, Widget? child) {
                      return Container(
                        width: AppSpacing.avatarLg,
                        height: AppSpacing.avatarLg,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppColors.white.withValues(alpha: 0.9),
                          foregroundImage: profileAvatarState.localFile != null
                              ? FileImage(profileAvatarState.localFile!)
                              : null,
                          child: profileAvatarState.localFile == null
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0] : '?',
                                  style: AppTypography.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        formatPhoneForDisplay(user.phoneNumber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnDarkMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelAndPointsCard extends StatelessWidget {
  const _LevelAndPointsCard({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    final int level = user.level;
    final int pointsToNext = user.pointsToNextLevel;
    final int currentLevelMin = (level - 1) * 100;
    final int currentLevelMax = level * 100;
    final int clampedPoints = user.points.clamp(currentLevelMin, currentLevelMax);
    final double progress =
        (clampedPoints - currentLevelMin) / (currentLevelMax - currentLevelMin);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.radius14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryDark,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Level $level',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pointsToNext pts to next level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
            child: Container(
              height: AppSpacing.radius18,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                        gradient: LinearGradient(
                          colors: <Color>[
                            AppColors.primaryDark,
                            AppColors.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${user.points} pts',
                      style: AppTypography.badgeLabel.copyWith(
                        color: AppColors.textOnDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyRankCard extends StatelessWidget {
  const _WeeklyRankCard({
    required this.points,
    required this.onViewRankings,
  });

  final int points;
  final VoidCallback onViewRankings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.primaryDark,
              size: AppSpacing.iconLg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'My weekly rank',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$points pts this week',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewRankings,
            child: Text(
              'View rankings',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

