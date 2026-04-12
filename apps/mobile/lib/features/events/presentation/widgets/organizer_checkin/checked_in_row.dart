import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart' show CustomSemanticsAction;

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';

/// Checked-in attendee row.
/// Swipe left to remove. No persistent buttons to avoid the "tick does
/// nothing / x removes" UX confusion.
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
    final Color avatarColor =
        AppColors.avatarPalette[avatarIndex % AppColors.avatarPalette.length];
    final String initial =
        attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?';
    final String time =
        '${attendee.checkedInAt.hour.toString().padLeft(2, '0')}:'
        '${attendee.checkedInAt.minute.toString().padLeft(2, '0')}';

    return Semantics(
      label: context.l10n.eventsOrganizerRemoveAttendeeSemantic(attendee.name),
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        CustomSemanticsAction(
          label: context.l10n.eventsOrganizerRemoveAttendeeSemantic(
            attendee.name,
          ),
        ): onRemove,
      },
      child: Dismissible(
        key: ValueKey<String>(attendee.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.accentDanger,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(CupertinoIcons.trash, color: AppColors.white, size: 22),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.85),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: AppSpacing.sm,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                // Avatar with a small green "checked in" badge
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: AppTypography.badgeLabel.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.panelBackground,
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.checkmark,
                            size: 9,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        attendee.name,
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        time,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
