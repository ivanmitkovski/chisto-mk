import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/widgets/atoms/settings_group_divider.dart';
import 'package:flutter/material.dart';

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.showDividerBelow = false,
    this.showTrailingChevron = true,
    this.switchValue,
    this.onSwitchChanged,
  });

  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showDividerBelow;
  final bool showTrailingChevron;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isDestructive
        ? AppColors.accentDanger
        : AppColors.textPrimary;
    return Column(
      children: <Widget>[
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(leadingIcon, size: 18, color: titleColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs / 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (switchValue != null)
                    Switch.adaptive(
                      value: switchValue!,
                      onChanged: onSwitchChanged,
                      activeThumbColor: AppColors.primary,
                    )
                  else if (showTrailingChevron)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDividerBelow) const SettingsGroupDivider(),
      ],
    );
  }
}
