import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/presentation/navigation/profile_actions_handler.dart';
import 'package:chisto_mobile/shared/widgets/settings_list_tile.dart';

/// Account details, support, and account action groups on the profile home.
class ProfileSettingsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.profileAccountDetailsSection,
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
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.l10n.profileSupportSection,
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
          child: MergeSemantics(
            child: SettingsListTile(
              leadingIcon: Icons.help_outline_rounded,
              title: context.l10n.profileHelpCenterTile,
              onTap: () => ProfileActionsHandler.handleHelp(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.l10n.profileAccountSection,
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
              MergeSemantics(
                child: SettingsListTile(
                  leadingIcon: Icons.logout_rounded,
                  title: context.l10n.profileSignOutTile,
                  onTap: () => ProfileActionsHandler.handleLogout(context),
                  showTrailingChevron: false,
                  showDividerBelow: true,
                ),
              ),
              MergeSemantics(
                child: SettingsListTile(
                  leadingIcon: Icons.person_remove_rounded,
                  title: context.l10n.profileDeleteAccountTile,
                  onTap: () =>
                      ProfileActionsHandler.handleDeleteAccount(context),
                  isDestructive: true,
                  showTrailingChevron: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
