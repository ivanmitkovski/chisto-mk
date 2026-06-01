import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final DateTime local = date.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(local.year, local.month, local.day);
    final String label;
    if (day == today) {
      label = context.l10n.eventChatToday;
    } else if (day == today.subtract(const Duration(days: 1))) {
      label = context.l10n.eventChatYesterday;
    } else {
      label = DateFormat.yMMMd(
        Localizations.localeOf(context).toString(),
      ).format(local);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs + 1,
          ),
          decoration: BoxDecoration(
            color: AppColors.panelBackground.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: AppShadows.chatDatePill(),
          ),
          child: Text(
            label,
            style: AppTypography.eventsChatTimestamp(
              Theme.of(context).textTheme,
            ).copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.1),
          ),
        ),
      ),
    );
  }
}
