import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_filter_pill_bar.dart';
import 'package:flutter/material.dart';

enum NotificationInboxFilter { all, unread }

/// Inbox filter row — same [AppFilterPillBar] / feed chip styling as home and events.
class NotificationsFilterBar extends StatelessWidget {
  const NotificationsFilterBar({
    super.key,
    required this.active,
    required this.onSelected,
  });

  final NotificationInboxFilter active;
  final ValueChanged<NotificationInboxFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppFilterPillBar<NotificationInboxFilter>(
      variant: AppFilterPillVariant.feedChip,
      items: <FilterPillItem<NotificationInboxFilter>>[
        FilterPillItem<NotificationInboxFilter>(
          value: NotificationInboxFilter.all,
          label: context.l10n.notificationsFilterAll,
          semanticsLabel: context.l10n.feedFilterSemantic(
            context.l10n.notificationsFilterAll,
          ),
        ),
        FilterPillItem<NotificationInboxFilter>(
          value: NotificationInboxFilter.unread,
          label: context.l10n.notificationsFilterUnread,
          semanticsLabel: context.l10n.feedFilterSemantic(
            context.l10n.notificationsFilterUnread,
          ),
        ),
      ],
      selected: active,
      onSelected: onSelected,
    );
  }
}
