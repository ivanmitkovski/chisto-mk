import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_radii.dart';
import 'package:chisto_mobile/core/theme/app_shadows.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/safety/domain/blocked_user_row.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:flutter/material.dart';

/// One blocked user row on [ProfileBlockedUsersScreen].
class BlockedUserListTile extends StatelessWidget {
  const BlockedUserListTile({
    super.key,
    required this.row,
    required this.unblockLabel,
    required this.onUnblock,
    this.isUnblocking = false,
  });

  final BlockedUserRow row;
  final String unblockLabel;
  final VoidCallback? onUnblock;
  final bool isUnblocking;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppRadii.r18,
        boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              row.displayName,
              style: AppTypography.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (isUnblocking)
            const AppLoadingIndicator(size: AppLoadingIndicatorSize.sm)
          else
            TextButton(
              onPressed: onUnblock,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                textStyle: AppTypography.textTheme.labelLarge,
              ),
              child: Text(unblockLabel),
            ),
        ],
      ),
    );
  }
}
