import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/presentation/navigation/profile_actions_handler.dart';
import 'package:feature_profile/src/presentation/screens/profile_blocked_users_screen.dart';
import 'package:feature_profile/src/presentation/widgets/profile_app_version_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Account details, support, and account action groups on the profile home.
class ProfileSettingsSection extends ConsumerWidget {
  const ProfileSettingsSection({
    super.key,
    required this.languageListSubtitle,
    required this.onGeneralInfoTap,
    required this.onLanguageTap,
    required this.onPasswordTap,
  });

  final String languageListSubtitle;
  final VoidCallback onGeneralInfoTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onPasswordTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.profileAccountDetailsSection,
          style: AppTypographySurfaces.profileSettingsSectionLabel(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: AppRadii.r18,
            boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
          ),
          child: ClipRRect(
            borderRadius: AppRadii.r18,
            child: Column(
              children: <Widget>[
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.person_outline_rounded,
                    title: context.l10n.profileGeneralInfoTile,
                    onTap: onGeneralInfoTap,
                    showDividerBelow: true,
                  ),
                ),
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.language_rounded,
                    title: context.l10n.profileLanguageTile,
                    subtitle: languageListSubtitle,
                    onTap: onLanguageTap,
                    showDividerBelow: true,
                  ),
                ),
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.lock_outline_rounded,
                    title: context.l10n.profilePasswordTile,
                    onTap: onPasswordTap,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.l10n.profileSupportSection,
          style: AppTypographySurfaces.profileSettingsSectionLabel(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: AppRadii.r18,
            boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
          ),
          child: ClipRRect(
            borderRadius: AppRadii.r18,
            child: Column(
              children: <Widget>[
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.privacy_tip_outlined,
                    title: context.l10n.profilePrivacyPolicyTile,
                    onTap: () =>
                        ProfileActionsHandler.handlePrivacyPolicy(context, ref),
                    showDividerBelow: true,
                  ),
                ),
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.description_outlined,
                    title: context.l10n.profileTermsTile,
                    onTap: () => ProfileActionsHandler.handleTerms(context, ref),
                    showDividerBelow: true,
                  ),
                ),
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.help_outline_rounded,
                    title: context.l10n.profileHelpCenterTile,
                    onTap: () => ProfileActionsHandler.handleHelp(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.l10n.profileSafetySection,
          style: AppTypographySurfaces.profileSettingsSectionLabel(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: AppRadii.r18,
            boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
          ),
          child: ClipRRect(
            borderRadius: AppRadii.r18,
            child: Column(
              children: <Widget>[
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.flag_outlined,
                    title: context.l10n.profileSafetyReportIssueTile,
                    onTap: () =>
                        ProfileActionsHandler.handleSafetyReport(context, ref),
                    showDividerBelow: true,
                  ),
                ),
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.block_flipped,
                    title: context.l10n.profileBlockedUsersTile,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileBlockedUsersScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.l10n.profileAccountSection,
          style: AppTypographySurfaces.profileSettingsSectionLabel(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: AppRadii.r18,
            boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
          ),
          child: ClipRRect(
            borderRadius: AppRadii.r18,
            child: Column(
              children: <Widget>[
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.logout_rounded,
                    title: context.l10n.profileSignOutTile,
                    onTap: () => ProfileActionsHandler.handleLogout(context, ref),
                    showTrailingChevron: false,
                    showDividerBelow: true,
                  ),
                ),
                MergeSemantics(
                  child: SettingsListTile(
                    leadingIcon: Icons.person_remove_rounded,
                    title: context.l10n.profileDeleteAccountTile,
                    onTap: () =>
                        ProfileActionsHandler.handleDeleteAccount(context, ref),
                    isDestructive: true,
                    showTrailingChevron: false,
                  ),
                ),
              ],
            ),
          ),
        ),
        const ProfileAppVersionFooter(),
      ],
    );
  }
}
