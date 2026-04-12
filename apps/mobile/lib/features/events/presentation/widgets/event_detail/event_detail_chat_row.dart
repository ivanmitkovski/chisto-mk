import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Tappable row inside [EventDetailGroupedPanel] to open event chat.
class EventDetailChatRow extends StatelessWidget {
  const EventDetailChatRow({
    super.key,
    required this.unreadCount,
    required this.onOpen,
  });

  final int unreadCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unreadCount > 0
          ? '${context.l10n.eventChatRowTitle}, $unreadCount unread'
          : context.l10n.eventChatRowTitle,
      child: InkWell(
        onTap: () {
          AppHaptics.softTransition();
          onOpen();
        },
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: <Widget>[
              Icon(
                CupertinoIcons.chat_bubble_2_fill,
                size: AppSpacing.iconMd,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.eventChatRowTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
