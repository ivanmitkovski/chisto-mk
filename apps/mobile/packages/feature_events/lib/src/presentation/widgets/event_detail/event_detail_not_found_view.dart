import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/presentation/navigation/events_navigation.dart';
import 'package:flutter/cupertino.dart';

/// Full-screen body when an event id cannot be loaded (removed or invalid link).
class EventDetailNotFoundView extends StatelessWidget {
  const EventDetailNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    void browseOrPop() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        EventsNavigation.openFeed(context);
      }
    }

    return SafeArea(
      child: AppEmptyState(
        icon: CupertinoIcons.calendar,
        title: context.l10n.eventsEventNotFoundTitle,
        subtitle: context.l10n.eventsEventNotFoundBody,
        action: AppButton.primary(
          label: context.l10n.eventsDetailBrowseEvents,
          onPressed: browseOrPop,
        ),
      ),
    );
  }
}
