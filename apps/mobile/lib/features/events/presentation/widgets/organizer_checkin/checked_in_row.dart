import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';

class CheckedInRow extends StatelessWidget {
  const CheckedInRow({
    super.key,
    required this.attendee,
    required this.onRemove,
    required this.avatarIndex,
  });

  final CheckedInAttendee attendee;
  final VoidCallback onRemove;
  final int avatarIndex;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color avatarColor =
        AppColors.avatarPalette[avatarIndex % AppColors.avatarPalette.length];
    final String initial = attendee.name.isNotEmpty
        ? attendee.name[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: AppSpacing.xxl,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              attendee.name,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${attendee.checkedInAt.hour.toString().padLeft(2, '0')}:${attendee.checkedInAt.minute.toString().padLeft(2, '0')}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Remove attendee',
            button: true,
            child: CupertinoButton(
              minimumSize: const Size(30, 30),
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 22,
                color: AppColors.accentDanger,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 22,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
