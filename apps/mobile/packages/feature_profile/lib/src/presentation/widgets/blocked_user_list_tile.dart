import 'package:design_system/design_system.dart';
import 'package:feature_safety/feature_safety.dart';
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
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
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
            AppButton.text(
              label: unblockLabel,
              onPressed: onUnblock,
              expand: false,
            ),
        ],
      ),
    );
  }
}
