import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/utils/profile_level_tier.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_summary_card.dart';
import 'package:chisto_mobile/shared/widgets/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/profile/data/profile_avatar_state.dart';
import 'package:chisto_mobile/features/profile/presentation/navigation/profile_actions_handler.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_general_info_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_language_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_password_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_screen_skeleton.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_points_history_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/weekly_rankings_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/no_overscroll_overlay_scroll_behavior.dart';
import 'package:chisto_mobile/shared/widgets/settings_list_tile.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:chisto_mobile/shared/widgets/profile_avatar_peek_overlay.dart';

String? _profilePeekNormalizeUrl(String? url) {
  final String? trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

double _levelProgressBarWidthFactor(double progress) {
  final double p = progress.clamp(0.0, 1.0);
  if (p <= 0) return 0.0;
  if (p >= 1.0) return 1.0;
  return p < 0.04 ? 0.04 : p;
}

String _profileLanguageListSubtitle(BuildContext context) {
  final Locale? override = ServiceLocator.instance.appLocaleOverride.value;
  if (override == null) {
    return context.l10n.profileLanguageSubtitleDevice;
  }
  switch (override.languageCode) {
    case 'mk':
      return context.l10n.profileLanguageNameMk;
    case 'sq':
      return context.l10n.profileLanguageNameSq;
    default:
      return context.l10n.profileLanguageNameEn;
  }
}

bool _profileHeaderHasPeekablePhoto(ProfileUser user) {
  if (profileAvatarState.localFile != null) return true;
  return _profilePeekNormalizeUrl(
        profileAvatarState.remoteUrl ?? user.avatarUrl,
      ) !=
      null;
}

ImageProvider? _profileHeaderPeekImageProvider(ProfileUser user) {
  final File? local = profileAvatarState.localFile;
  if (local != null) return FileImage(local);
  final String? url = _profilePeekNormalizeUrl(
    profileAvatarState.remoteUrl ?? user.avatarUrl,
  );
  if (url == null) return null;
  return NetworkImage(url);
}

/// Extends the clip rect below the scroll viewport so card shadows are not cut
/// off. Top stays at 0 so list content never paints into [_ProfileHeader].
class _ProfileScrollBottomShadowClipper extends CustomClipper<Rect> {
  const _ProfileScrollBottomShadowClipper({required this.bottomExtension});

  final double bottomExtension;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height + bottomExtension);

  @override
  bool shouldReclip(covariant _ProfileScrollBottomShadowClipper oldClipper) =>
      oldClipper.bottomExtension != bottomExtension;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// [SingleTickerProviderStateMixin] satisfies Flutter’s ticker-mode wiring for
/// this state; omitting it caused `NoSuchMethodError` on `TickerMode` updates
/// (e.g. after hot reload). No [AnimationController] is attached here.
class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minSkeletonDuration = Duration(milliseconds: 400);
  AppError? _profileLoadError;
  ProfileUser? _profileUser;
  ReportCapacity? _reportCapacity;
  bool _capacityLoadInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    ServiceLocator.instance.profileNeedsRefresh.addListener(
      _onProfileNeedsRefresh,
    );
    ServiceLocator.instance.appLocaleOverride.addListener(_onAppLocaleChanged);
  }

  void _onAppLocaleChanged() {
    if (mounted) setState(() {});
  }

  void _onProfileNeedsRefresh() {
    if (mounted) _loadProfile();
  }

  Future<ReportCapacity?> _fetchCapacitySafe() async {
    try {
      return await ServiceLocator.instance.reportsApiRepository
          .getReportingCapacity();
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureMinSkeletonVisible(DateTime loadStarted) async {
    final int elapsed = DateTime.now().difference(loadStarted).inMilliseconds;
    if (elapsed < _minSkeletonDuration.inMilliseconds) {
      await Future<void>.delayed(
        Duration(milliseconds: _minSkeletonDuration.inMilliseconds - elapsed),
      );
    }
  }

  Future<void> _loadProfile() async {
    final bool hadUser = _profileUser != null;
    setState(() {
      _profileLoadError = null;
      _capacityLoadInFlight = true;
    });

    final DateTime loadStarted = DateTime.now();
    final Future<ReportCapacity?> capacityFuture = _fetchCapacitySafe();

    try {
      final ProfileUser? loaded = await _fetchProfileUser();
      if (!mounted) return;

      final ReportCapacity? capacity = await capacityFuture;
      if (!mounted) return;

      if (!hadUser && loaded != null) {
        await _ensureMinSkeletonVisible(loadStarted);
        if (!mounted) return;
      }

      final bool authenticated =
          ServiceLocator.instance.authState.isAuthenticated;
      setState(() {
        _profileUser = loaded;
        _profileLoadError = authenticated && loaded == null
            ? AppError.unknown()
            : null;
        _reportCapacity = capacity;
        _capacityLoadInFlight = false;
      });
      profileAvatarState.setRemoteUrl(loaded?.avatarUrl);
    } on AppError catch (e) {
      await capacityFuture;
      if (!mounted) return;
      if (_isAuthError(e.code)) {
        setState(() => _capacityLoadInFlight = false);
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      if (hadUser) {
        setState(() {
          _capacityLoadInFlight = false;
          _profileLoadError = null;
        });
        if (mounted) {
          AppSnack.show(
            context,
            message: context.l10n.profileRefreshFailedSnack,
            type: AppSnackType.warning,
          );
        }
      } else {
        setState(() {
          _capacityLoadInFlight = false;
          _profileLoadError = e;
        });
      }
    } catch (e) {
      await capacityFuture;
      if (!mounted) return;
      if (hadUser) {
        setState(() {
          _capacityLoadInFlight = false;
          _profileLoadError = null;
        });
        if (mounted) {
          AppSnack.show(
            context,
            message: context.l10n.profileRefreshFailedSnack,
            type: AppSnackType.warning,
          );
        }
      } else {
        setState(() {
          _capacityLoadInFlight = false;
          _profileLoadError = AppError.network(cause: e);
        });
      }
    }
  }

  Future<ProfileUser?> _fetchProfileUser() async {
    final authState = ServiceLocator.instance.authState;
    if (!authState.isAuthenticated || authState.userId == null) return null;

    return ServiceLocator.instance.profileRepository.getMe();
  }

  static bool _isAuthError(String code) =>
      code == 'UNAUTHORIZED' ||
      code == 'INVALID_TOKEN_USER' ||
      code == 'ACCOUNT_NOT_ACTIVE';

  @override
  void dispose() {
    ProfileAvatarPeek.hide();
    ServiceLocator.instance.profileNeedsRefresh.removeListener(
      _onProfileNeedsRefresh,
    );
    ServiceLocator.instance.appLocaleOverride.removeListener(
      _onAppLocaleChanged,
    );
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _loadProfile();
  }

  /// Insets content using [MediaQuery.viewPadding] as a minimum so layout stays
  /// correct when [MediaQuery.padding] is zero (e.g. edge-to-edge / translucent
  /// status bar on iOS).
  Widget _profileSafeBody(Widget child) {
    final EdgeInsets v = MediaQuery.viewPaddingOf(context);
    return SafeArea(
      minimum: EdgeInsets.only(
        top: v.top,
        left: v.left,
        right: v.right,
        bottom: v.bottom,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfileUser? loaded = _profileUser;
    final bool authenticated =
        ServiceLocator.instance.authState.isAuthenticated;
    final String phase = _profileBodyPhase(loaded, authenticated);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: _profileSafeBody(
        AnimatedPhaseSwitcher(
          phaseKey: phase,
          child: _profileBodyForPhase(phase, loaded),
        ),
      ),
    );
  }

  String _profileBodyPhase(ProfileUser? loaded, bool authenticated) {
    if (_profileLoadError != null) return 'error';
    if (loaded == null) return authenticated ? 'skeleton' : 'guest';
    return 'loaded';
  }

  Widget _profileBodyForPhase(String phase, ProfileUser? loaded) {
    switch (phase) {
      case 'error':
        return AppErrorView(error: _profileLoadError!, onRetry: _loadProfile);
      case 'skeleton':
        return const ProfileScreenSkeleton();
      case 'guest':
        return Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.primaryDark,
              strokeWidth: 2.5,
            ),
          ),
        );
      case 'loaded':
        return _buildAuthenticatedProfileBody(loaded!);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAuthenticatedProfileBody(ProfileUser user) {
    return Column(
      children: <Widget>[
        _ProfileHeader(
          user: user,
          onProfileUpdated: (ProfileUser u) => setState(() => _profileUser = u),
        ),
        Expanded(
          child: ClipRect(
            clipper: const _ProfileScrollBottomShadowClipper(
              bottomExtension: AppSpacing.xxl + AppSpacing.xl,
            ),
            child: ScrollConfiguration(
              behavior: const NoOverscrollOverlayScrollBehavior(),
              child: CustomScrollView(
                clipBehavior: Clip.none,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  CupertinoSliverRefreshControl(onRefresh: _handleRefresh),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl + AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _LevelAndPointsCard(
                            user: user,
                            onOpenPointsHistory: () {
                              AppHaptics.softTransition();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProfilePointsHistoryScreen(
                                    summaryUser: user,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_capacityLoadInFlight &&
                              _reportCapacity == null) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            const ProfileReportCreditsSkeleton(),
                          ] else if (_reportCapacity != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            ReportCapacitySummaryCard(
                              capacity: _reportCapacity!,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _WeeklyRankCard(
                            user: user,
                            onViewRankings: () {
                              AppHaptics.softTransition();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const WeeklyRankingsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            context.l10n.profileAccountDetailsSection,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radius18,
                              ),
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
                                  title: context.l10n.profileGeneralInfoTile,
                                  onTap: () async {
                                    AppHaptics.tap();
                                    final ProfileUser? updated =
                                        await Navigator.of(
                                          context,
                                        ).push<ProfileUser>(
                                          MaterialPageRoute<ProfileUser>(
                                            builder: (_) =>
                                                ProfileGeneralInfoScreen(
                                                  user: user,
                                                ),
                                          ),
                                        );
                                    if (!mounted || updated == null) return;
                                    setState(() => _profileUser = updated);
                                  },
                                  showDividerBelow: true,
                                ),
                                SettingsListTile(
                                  leadingIcon: Icons.language_rounded,
                                  title: context.l10n.profileLanguageTile,
                                  subtitle: _profileLanguageListSubtitle(
                                    context,
                                  ),
                                  onTap: () {
                                    AppHaptics.tap();
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ProfileLanguageScreen(),
                                      ),
                                    );
                                  },
                                  showDividerBelow: true,
                                ),
                                SettingsListTile(
                                  leadingIcon: Icons.lock_outline_rounded,
                                  title: context.l10n.profilePasswordTile,
                                  onTap: () {
                                    AppHaptics.tap();
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ProfilePasswordScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            context.l10n.profileSupportSection,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radius18,
                              ),
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
                              title: context.l10n.profileHelpCenterTile,
                              onTap: () =>
                                  ProfileActionsHandler.handleHelp(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            context.l10n.profileAccountSection,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radius18,
                              ),
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
                                  title: context.l10n.profileSignOutTile,
                                  onTap: () =>
                                      ProfileActionsHandler.handleLogout(
                                        context,
                                      ),
                                  showTrailingChevron: false,
                                  showDividerBelow: true,
                                ),
                                SettingsListTile(
                                  leadingIcon: Icons.person_remove_rounded,
                                  title: context.l10n.profileDeleteAccountTile,
                                  onTap: () =>
                                      ProfileActionsHandler.handleDeleteAccount(
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, this.onProfileUpdated});

  final ProfileUser user;
  final void Function(ProfileUser)? onProfileUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryDark, AppColors.primary],
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
            const Row(children: <Widget>[AppBackButton(), Spacer()]),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AnimatedBuilder(
                  animation: profileAvatarState,
                  builder: (BuildContext context, Widget? child) {
                    final bool canPeek = _profileHeaderHasPeekablePhoto(user);
                    return GestureDetector(
                      onTap: () async {
                        AppHaptics.tap();
                        final ProfileUser? updated = await Navigator.of(context)
                            .push<ProfileUser>(
                              MaterialPageRoute<ProfileUser>(
                                builder: (_) =>
                                    ProfileGeneralInfoScreen(user: user),
                              ),
                            );
                        if (updated != null) {
                          onProfileUpdated?.call(updated);
                        }
                      },
                      onLongPress: canPeek
                          ? () {
                              final ImageProvider? img =
                                  _profileHeaderPeekImageProvider(user);
                              if (img == null) return;
                              ProfileAvatarPeek.show(
                                context,
                                image: img,
                                semanticLabel:
                                    context.l10n.profileAvatarPeekSemantic,
                              );
                            }
                          : null,
                      onLongPressUp: canPeek ? ProfileAvatarPeek.hide : null,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
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
                        child: profileAvatarState.localFile != null
                            ? CircleAvatar(
                                backgroundColor: AppColors.white.withValues(
                                  alpha: 0.9,
                                ),
                                foregroundImage: FileImage(
                                  profileAvatarState.localFile!,
                                ),
                              )
                            : AppAvatar(
                                name: user.name,
                                size: AppSpacing.avatarLg,
                                imageUrl:
                                    profileAvatarState.remoteUrl ??
                                    user.avatarUrl,
                              ),
                      ),
                    );
                  },
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
  const _LevelAndPointsCard({
    required this.user,
    required this.onOpenPointsHistory,
  });

  final ProfileUser user;
  final VoidCallback onOpenPointsHistory;

  @override
  Widget build(BuildContext context) {
    final double progress = user.levelProgress.clamp(0.0, 1.0);
    final double widthFactor = _levelProgressBarWidthFactor(progress);
    final int segmentTotal = user.pointsInLevel + user.pointsToNextLevel;

    return Semantics(
      button: true,
      label: context.l10n.profilePointsHistoryOpenSemantic,
      child: Container(
        width: double.infinity,
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
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpenPointsHistory,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radius14,
                          ),
                        ),
                        child: Icon(
                          profileTierIcon(user.levelTierKey),
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
                              profileTierTitle(context, user),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.profilePtsToNextLevel(
                                user.pointsToNextLevel,
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusCircle,
                    ),
                    child: SizedBox(
                      height: AppSpacing.radius18,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ColoredBox(color: AppColors.inputFill),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: widthFactor,
                              heightFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusCircle,
                                  ),
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      AppColors.primaryDark,
                                      AppColors.primary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (segmentTotal > 0)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            context.l10n.profileLevelXpSegment(
                              user.pointsInLevel,
                              segmentTotal,
                            ),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            context.l10n.profileLifetimeXpOnBar(
                              user.totalPointsEarned,
                            ),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      context.l10n.profileLifetimeXpOnBar(
                        user.totalPointsEarned,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyRankCard extends StatelessWidget {
  const _WeeklyRankCard({required this.user, required this.onViewRankings});

  final ProfileUser user;
  final VoidCallback onViewRankings;

  String _detailLine(BuildContext context) {
    if (user.weeklyRank != null && user.weeklyPoints > 0) {
      return context.l10n.profileMyWeeklyRankDetailRanked(
        user.weeklyRank!,
        user.weeklyPoints,
      );
    }
    if (user.weeklyPoints > 0) {
      return context.l10n.profileMyWeeklyRankDetailPointsOnly(
        user.weeklyPoints,
      );
    }
    return context.l10n.profileMyWeeklyRankNoPoints;
  }

  @override
  Widget build(BuildContext context) {
    final String detail = _detailLine(context);
    return Semantics(
      button: true,
      label:
          '${context.l10n.profileMyWeeklyRankTitle}. $detail. ${context.l10n.profileViewRankings}',
      child: Container(
        width: double.infinity,
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
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onViewRankings,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                          context.l10n.profileMyWeeklyRankTitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
