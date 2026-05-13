import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_action_sheet.dart';
import 'package:flutter/material.dart';

/// Source for the profile avatar capture flow (not [ImageSource], keeps picker types internal).
enum ProfileAvatarSource { selfie, gallery, remove }

/// Bottom sheet: selfie vs Photos, using the same chrome as report sheets.
Future<ProfileAvatarSource?> showProfileAvatarSourceSheet(
  BuildContext context, {
  bool showRemoveOption = false,
}) {
  return showAppActionSheet<ProfileAvatarSource>(
    context: context,
    builder: (BuildContext context) {
      final l10n = context.l10n;
      return ReportSheetScaffold(
        title: l10n.profileAvatarSourceTitle,
        subtitle: l10n.profileAvatarSourceSubtitle,
        trailing: ReportCircleIconButton(
          icon: Icons.close_rounded,
          semanticLabel: l10n.semanticsClose,
          onTap: () {
            AppHaptics.sheetDismiss();
            Navigator.of(context).pop();
          },
        ),
        maxHeightFactor: 0.72,
        showHeaderDivider: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: AppSpacing.xs),
              _ProfileAvatarSourceTile(
                icon: Icons.camera_front_rounded,
                label: l10n.profileAvatarSourceCamera,
                description: l10n.profileAvatarSourceCameraHint,
                badgeLabel: l10n.profileAvatarSourceRecommended,
                emphasized: true,
                onTap: () {
                  AppHaptics.medium();
                  Navigator.of(context).pop(ProfileAvatarSource.selfie);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProfileAvatarSourceTile(
                icon: Icons.photo_library_rounded,
                label: l10n.profileAvatarSourcePhotos,
                description: l10n.profileAvatarSourcePhotosHint,
                onTap: () {
                  AppHaptics.light();
                  Navigator.of(context).pop(ProfileAvatarSource.gallery);
                },
              ),
              if (showRemoveOption) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _ProfileAvatarSourceTile(
                  icon: Icons.hide_image_outlined,
                  label: l10n.profileAvatarSourceRemove,
                  description: l10n.profileAvatarSourceRemoveHint,
                  destructive: true,
                  onTap: () {
                    AppHaptics.warning();
                    Navigator.of(context).pop(ProfileAvatarSource.remove);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _ProfileAvatarSourceTile extends StatelessWidget {
  const _ProfileAvatarSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
    this.badgeLabel,
    this.emphasized = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onTap;
  final String? badgeLabel;
  final bool emphasized;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = destructive
        ? AppColors.accentDanger.withValues(alpha: 0.06)
        : emphasized
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.inputFill;
    final Color borderColor = destructive
        ? AppColors.accentDanger.withValues(alpha: 0.28)
        : emphasized
        ? AppColors.primaryDark.withValues(alpha: 0.22)
        : AppColors.divider.withValues(alpha: 0.9);
    final Color iconBackground = destructive
        ? AppColors.accentDanger.withValues(alpha: 0.12)
        : emphasized
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.panelBackground;
    final Color chevronBackground = destructive
        ? AppColors.accentDanger.withValues(alpha: 0.1)
        : emphasized
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.panelBackground;
    final Color chevronColor = destructive
        ? AppColors.accentDanger
        : emphasized
        ? AppColors.primaryDark
        : AppColors.textMuted;

    return Semantics(
      button: true,
      label: description != null ? '$label. $description' : label,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: destructive
              ? AppColors.accentDanger.withValues(alpha: 0.12)
              : AppColors.primary.withValues(alpha: 0.08),
          highlightColor: destructive
              ? AppColors.accentDanger.withValues(alpha: 0.06)
              : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSpacing.radius22),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppSpacing.radius22),
              border: Border.all(color: borderColor),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(
                    alpha: emphasized ? 0.02 : 0.012,
                  ),
                  blurRadius: emphasized ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: destructive
                        ? AppColors.accentDanger
                        : emphasized
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              label,
                              style: AppTypography.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (badgeLabel != null) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            ReportStatePill(
                              label: badgeLabel!,
                              tone: ReportSurfaceTone.accent,
                              emphasized: true,
                            ),
                          ],
                        ],
                      ),
                      if (description != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description!,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: chevronBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: chevronColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
