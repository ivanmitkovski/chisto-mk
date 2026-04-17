import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
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
              ? _iconBubble(icon)
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
                  child: _iconBubble(icon),
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
            FilledButton(
              onPressed: onCreateEvent,
              child: Text(l10n.eventsEmptyActionCreateEvent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBubble(IconData icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 36, color: AppColors.primaryDark),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.search,
              size: 36,
              color: AppColors.textMuted,
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
            FilledButton(
              onPressed: onCreateEvent,
              child: Text(l10n.eventsEmptyActionCreateEvent),
            ),
          ],
        ],
      ),
    );
  }
}
