import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';

class EventsEmptyState extends StatelessWidget {
  const EventsEmptyState({super.key, required this.filter});

  final EcoEventFilter filter;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;
    final IconData icon;
    switch (filter) {
      case EcoEventFilter.all:
        title = 'No eco events yet';
        subtitle = 'Be the first to create one! Tap + above to get started.';
        icon = CupertinoIcons.calendar_badge_plus;
      case EcoEventFilter.upcoming:
        title = 'No upcoming events';
        subtitle = 'Create one to get volunteers together.';
        icon = CupertinoIcons.clock;
      case EcoEventFilter.nearby:
        title = 'No nearby events';
        subtitle = 'Try a different filter or create an event in your area.';
        icon = CupertinoIcons.location;
      case EcoEventFilter.past:
        title = 'No past events';
        subtitle = 'Completed events will show here.';
        icon = CupertinoIcons.checkmark_circle;
      case EcoEventFilter.myEvents:
        title = 'No events yet';
        subtitle = 'Join or create an event to see it here.';
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
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
            'No results for "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Try a different search term or check your spelling.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
