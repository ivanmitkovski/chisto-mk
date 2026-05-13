import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

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

    // Top-align so when the shell shrinks for the keyboard, this block does not
    // re-center vertically (which looks like the content "jumping").
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              reduceMotion
                  ? _FeedEmptyIllustration(icon: icon)
                  : TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.92, end: 1.0),
                      duration: AppMotion.slow,
                      curve: AppMotion.emphasized,
                      builder: (_, double value, Widget? child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(scale: value, child: child),
                        );
                      },
                      child: _FeedEmptyIllustration(icon: icon),
                    ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.emptyStateTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.emptyStateSubtitle,
              ),
              if (showClearFilters && onClearFilters != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: onClearFilters,
                  child: Text(l10n.eventsEmptyActionClearFilters),
                ),
              ],
              if (onCreateEvent != null) ...<Widget>[
                SizedBox(
                  height: showClearFilters ? AppSpacing.md : AppSpacing.lg,
                ),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: l10n.eventsEmptyActionCreateEvent,
                    onPressed: onCreateEvent!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _FeedEmptyIllustration(icon: CupertinoIcons.search),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.eventsSearchEmptyTitle(query),
                textAlign: TextAlign.center,
                style: AppTypography.emptyStateTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.eventsSearchEmptySubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.emptyStateSubtitle,
              ),
              if (query.trim().length >= 2) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.eventsSearchEmptyScopeHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.eventsSupportingCaption(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
              if (onClearSearch != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: onClearSearch,
                  child: Text(l10n.eventsSearchEmptyClearSearch),
                ),
              ],
              if (onCreateEvent != null) ...<Widget>[
                SizedBox(
                  height: onClearSearch != null ? AppSpacing.md : AppSpacing.lg,
                ),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: l10n.eventsEmptyActionCreateEvent,
                    onPressed: onCreateEvent!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Same visual language as [AppEmptyState] (inputFill circle, muted icon).
class _FeedEmptyIllustration extends StatelessWidget {
  const _FeedEmptyIllustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final double diameter = AppSpacing.avatarLg + AppSpacing.xs;
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: AppColors.inputFill,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: AppSpacing.xl,
        color: AppColors.textMuted,
      ),
    );
  }
}
