import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String title;
    final String subtitle;
    final IconData icon;
    final AppLocalizations l10n = context.l10n;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          reduceMotion
              ? _iconBubble(context, icon)
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasized,
                  builder: (_, double value, Widget? child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(scale: value, child: child),
                    );
                  },
                  child: _iconBubble(context, icon),
                ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.eventsEmptyStateTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.eventsEmptyStateSubtitle(
                Theme.of(context).textTheme,
              ),
            ),
          ),
          if (showClearFilters && onClearFilters != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onClearFilters,
              child: Text(l10n.eventsEmptyActionClearFilters),
            ),
          ],
          if (onCreateEvent != null) ...<Widget>[
            SizedBox(height: showClearFilters ? AppSpacing.sm : AppSpacing.lg),
            _CreateEventButton(
              label: l10n.eventsEmptyActionCreateEvent,
              colorScheme: colorScheme,
              onPressed: onCreateEvent!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBubble(BuildContext context, IconData icon) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 36, color: colorScheme.onPrimaryContainer),
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.search,
              size: 36,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.eventsSearchEmptyTitle(query),
            textAlign: TextAlign.center,
            style: AppTypography.eventsEmptyStateTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              l10n.eventsSearchEmptySubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.eventsEmptyStateSubtitle(
                Theme.of(context).textTheme,
              ),
            ),
          ),
          if (query.trim().length >= 2) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                l10n.eventsSearchEmptyScopeHint,
                textAlign: TextAlign.center,
                style: AppTypography.eventsSupportingCaption(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ],
          if (onClearSearch != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onClearSearch,
              child: Text(l10n.eventsSearchEmptyClearSearch),
            ),
          ],
          if (onCreateEvent != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _CreateEventButton(
              label: l10n.eventsEmptyActionCreateEvent,
              colorScheme: colorScheme,
              onPressed: onCreateEvent!,
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateEventButton extends StatelessWidget {
  const _CreateEventButton({
    required this.label,
    required this.colorScheme,
    required this.onPressed,
  });

  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(170, 48),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Text(label),
    );
  }
}
