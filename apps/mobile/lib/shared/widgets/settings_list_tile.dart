import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

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
  });

  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showDividerBelow;
  final bool showTrailingChevron;

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isDestructive ? AppColors.accentDanger : AppColors.textPrimary;
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
                    child: Icon(
                      leadingIcon,
                      size: 18,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          SizedBox(height: AppSpacing.xxs / 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showTrailingChevron)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDividerBelow)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.avatarLg),
            child: Divider(
              height: 1,
              color: AppColors.divider.withValues(alpha: 0.9),
            ),
          ),
      ],
    );
  }
}

