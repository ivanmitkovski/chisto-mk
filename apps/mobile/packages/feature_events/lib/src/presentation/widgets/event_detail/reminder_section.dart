import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReminderSection extends StatelessWidget {
  const ReminderSection({
    super.key,
    required this.event,
    required this.onToggleReminder,
  });

  final EcoEvent event;
  final VoidCallback onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String reminderState = event.reminderEnabled
        ? (event.reminderAt == null
              ? context.l10n.eventsReminderSectionEnabled
              : context.l10n.eventsReminderSectionSetFor(
                  TimeOfDay.fromDateTime(event.reminderAt!).format(context),
                ))
        : context.l10n.eventsReminderSectionDisabled;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: EventDetailSurfaceDecoration.detailModule(),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.eventsReminderSectionTitle,
                  style: AppTypography.eventsGroupedRowPrimary(textTheme),
                ),
                const SizedBox(height: 2),
                Text(
                  reminderState,
                  style: AppTypography.eventsListCardMeta(textTheme),
                ),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: onToggleReminder,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.radius10,
              vertical: AppSpacing.xxs,
            ),
            minimumSize: const Size(44, 44),
            child: Text(
              event.reminderEnabled
                  ? context.l10n.eventsReminderSectionDisable
                  : context.l10n.eventsReminderSectionEnable,
              style: AppTypography.eventsTextLinkEmphasis(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}
