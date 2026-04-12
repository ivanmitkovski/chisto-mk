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
  const EventsEmptyState({super.key, required this.filter});

  final EcoEventFilter filter;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: AppMotion.slow,
            curve: AppMotion.emphasized,
            builder: (_, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.emptyStateTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
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
            context.l10n.eventsSearchEmptyTitle(query),
            textAlign: TextAlign.center,
            style: AppTypography.emptyStateTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              context.l10n.eventsSearchEmptySubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
