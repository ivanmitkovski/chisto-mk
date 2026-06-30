import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventsEmptyState extends StatelessWidget {
  const EventsEmptyState({
    super.key,
    required this.filter,
    this.showClearFilters = false,
    this.onClearFilters,
    this.onCreateEvent,
  });

  final EcoEventFilter filter;
  final bool showClearFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String title;
    final String subtitle;
    final IconData icon;
    switch (filter) {
      case EcoEventFilter.all:
        title = l10n.eventsEmptyAllTitle;
        subtitle = l10n.eventsEmptyAllSubtitle;
        icon = CupertinoIcons.calendar_badge_plus;
      case EcoEventFilter.upcoming:
        title = l10n.eventsEmptyUpcomingTitle;
        subtitle = l10n.eventsEmptyUpcomingSubtitle;
        icon = CupertinoIcons.clock;
      case EcoEventFilter.nearby:
        title = l10n.eventsEmptyNearbyTitle;
        subtitle = l10n.eventsEmptyNearbySubtitle;
        icon = CupertinoIcons.location;
      case EcoEventFilter.past:
        title = l10n.eventsEmptyPastTitle;
        subtitle = l10n.eventsEmptyPastSubtitle;
        icon = CupertinoIcons.checkmark_circle;
      case EcoEventFilter.myEvents:
        title = l10n.eventsEmptyMyEventsTitle;
        subtitle = l10n.eventsEmptyMyEventsSubtitle;
        icon = CupertinoIcons.person_crop_circle;
    }

    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Widget empty = AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      alignment: AppEmptyStateAlignment.topCenter,
      maxWidth: AppSpacing.emptyStateMaxWidth,
      secondaryAction: showClearFilters && onClearFilters != null
          ? AppButton.text(
              label: l10n.eventsEmptyActionClearFilters,
              onPressed: onClearFilters,
            )
          : null,
      action: onCreateEvent != null
          ? AppButton.primary(
              label: l10n.eventsEmptyActionCreateEvent,
              onPressed: onCreateEvent,
            )
          : null,
    );

    if (reduceMotion) {
      return empty;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      builder: (_, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: empty,
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.query,
    this.onClearSearch,
    this.onCreateEvent,
  });

  final String query;
  final VoidCallback? onClearSearch;
  final VoidCallback? onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return AppEmptyState(
      icon: CupertinoIcons.search,
      title: l10n.eventsSearchEmptyTitle(query),
      subtitle: l10n.eventsSearchEmptySubtitle,
      alignment: AppEmptyStateAlignment.topCenter,
      maxWidth: AppSpacing.emptyStateMaxWidth,
      contentBelowSubtitle: query.trim().length >= 2
          ? Text(
              l10n.eventsSearchEmptyScopeHint,
              textAlign: TextAlign.center,
              style: AppTypography.eventsSupportingCaption(textTheme),
            )
          : null,
      secondaryAction: onClearSearch != null
          ? AppButton.text(
              label: l10n.eventsSearchEmptyClearSearch,
              onPressed: onClearSearch,
            )
          : null,
      action: onCreateEvent != null
          ? AppButton.primary(
              label: l10n.eventsEmptyActionCreateEvent,
              onPressed: onCreateEvent,
            )
          : null,
    );
  }
}
