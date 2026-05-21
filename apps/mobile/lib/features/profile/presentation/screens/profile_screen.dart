import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/core/providers/reports_providers.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_home_notifier.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_general_info_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_language_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_password_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_authenticated_body.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_screen_skeleton.dart';
import 'package:chisto_mobile/shared/widgets/molecules/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/organisms/profile_avatar_peek_overlay.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';

String _profileLanguageListSubtitle(BuildContext context, WidgetRef ref) {
  final Locale? override = ref.watch(appLocaleOverrideProvider);
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// [SingleTickerProviderStateMixin] satisfies Flutter’s ticker-mode wiring for
/// this state; omitting it caused `NoSuchMethodError` on `TickerMode` updates
/// (e.g. after hot reload). No [AnimationController] is attached here.
class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileHomeNotifierProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    ProfileAvatarPeek.hide();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(profileHomeNotifierProvider.notifier).loadProfile();
  }

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
    ref.listen<int>(profileRefreshTickProvider, (int? previous, int next) {
      if (previous != next && mounted) {
        ref.read(profileHomeNotifierProvider.notifier).loadProfile();
      }
    });
    final ProfileHomeState home = ref.watch(profileHomeNotifierProvider);
    final ProfileUser? loaded = home.profileUser;
    final bool authenticated = ref.watch(authStateProvider).isAuthenticated;
    final String phase = _profileBodyPhase(home, authenticated);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: _profileSafeBody(
        AnimatedPhaseSwitcher(
          phaseKey: phase,
          child: _profileBodyForPhase(context, phase, home, loaded),
        ),
      ),
    );
  }

  String _profileBodyPhase(ProfileHomeState home, bool authenticated) {
    if (home.profileLoadError != null) return 'error';
    if (home.profileUser == null) {
      return authenticated ? 'skeleton' : 'guest';
    }
    return 'loaded';
  }

  Widget _profileBodyForPhase(
    BuildContext context,
    String phase,
    ProfileHomeState home,
    ProfileUser? loaded,
  ) {
    switch (phase) {
      case 'error':
        return Semantics(
          container: true,
          liveRegion: true,
          label:
              '${context.l10n.profileErrorSemantic}. ${home.profileLoadError!.message}',
          child: AppErrorView(
            error: home.profileLoadError!,
            onRetry: () =>
                ref.read(profileHomeNotifierProvider.notifier).loadProfile(),
          ),
        );
      case 'skeleton':
        return Semantics(
          label: context.l10n.profileLoadingSemantic,
          liveRegion: true,
          child: const ProfileScreenSkeleton(),
        );
      case 'guest':
        return Semantics(
          label: context.l10n.profileLoadingSemantic,
          liveRegion: true,
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: AppLoadingIndicator(
                size: AppLoadingIndicatorSize.lg,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        );
      case 'loaded':
        final ProfileUser user = loaded!;
        return ProfileAuthenticatedBody(
          user: user,
          languageListSubtitle: _profileLanguageListSubtitle(context, ref),
          capacityLoadInFlight: home.capacityLoadInFlight,
          reportCapacity: home.reportCapacity,
          onRefresh: _handleRefresh,
          onProfileUpdated: (ProfileUser u) {
            ref.read(profileHomeNotifierProvider.notifier).updateUser(u);
          },
          onGeneralInfoTap: () async {
            final ProfileUser? updated =
                await Navigator.of(context).push<ProfileUser>(
              MaterialPageRoute<ProfileUser>(
                builder: (_) => ProfileGeneralInfoScreen(user: user),
              ),
            );
            if (!context.mounted || updated == null) return;
            ref.read(profileHomeNotifierProvider.notifier).updateUser(updated);
          },
          onLanguageTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfileLanguageScreen(),
              ),
            );
          },
          onPasswordTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfilePasswordScreen(),
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
