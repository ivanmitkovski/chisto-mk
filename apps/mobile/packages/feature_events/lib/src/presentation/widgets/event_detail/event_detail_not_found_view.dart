import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/presentation/navigation/events_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Full-screen body when an event id cannot be loaded (removed or invalid link).
class EventDetailNotFoundView extends StatelessWidget {
  const EventDetailNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    void browseOrPop() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        EventsNavigation.openFeed(context);
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                context.l10n.eventsEventNotFoundTitle,
                textAlign: TextAlign.center,
                style: AppTypography.eventsEmptyStateTitle(textTheme),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Icon(
              CupertinoIcons.calendar,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.85),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.eventsEventNotFoundBody,
              textAlign: TextAlign.center,
              style: AppTypography.eventsBodyProse(
                textTheme,
              ).copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: context.l10n.eventsDetailBrowseEvents,
              onPressed: browseOrPop,
            ),
          ],
        ),
      ),
    );
  }
}
