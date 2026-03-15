import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/sticky_bottom_cta.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class CleaningEventsTab extends StatelessWidget {
  const CleaningEventsTab({super.key, required this.site, required this.onCreateEvent});

  final PollutionSite site;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final double ctaHeight = 56 + AppSpacing.md * 2 + bottomSafe;
    final EventsRepository store = EventsRepositoryRegistry.instance;
    store.loadInitialIfNeeded();

    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? child) {
        final List<CleaningEvent> events = EventSiteResolver.cleaningEventsForSite(
          siteId: site.id,
          events: store.events,
        );
        return Stack(
          children: <Widget>[
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                ctaHeight + AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (events.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...events.map(
                      (CleaningEvent event) => _buildEventCard(context, event),
                    ),
                ],
              ),
            ),
            StickyBottomCTA(
              label: events.isEmpty
                  ? 'Create eco action'
                  : 'Schedule another action',
              onPressed: onCreateEvent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          onCreateEvent();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 32,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
                  Text(
                'No cleaning events yet',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Be the first to organize an eco action\nand rally volunteers for this site.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap to create',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEcoEvent(BuildContext context, CleaningEvent event) {
    final EventsRepository store = EventsRepositoryRegistry.instance;
    store.loadInitialIfNeeded();
    final EcoEvent? match = store.findById(event.id);
    if (match != null) {
      AppHaptics.softTransition();
      EventsNavigation.openDetail(context, eventId: match.id);
      return;
    }
    AppHaptics.warning();
    AppSnack.show(
      context,
      message: 'Event details are unavailable right now.',
      type: AppSnackType.warning,
    );
  }

  Widget _buildEventCard(BuildContext context, CleaningEvent event) {
    final String dateLabel =
        '${event.dateTime.day.toString().padLeft(2, '0')}.${event.dateTime.month.toString().padLeft(2, '0')}.${event.dateTime.year}';

    return GestureDetector(
      onTap: () => _navigateToEcoEvent(context, event),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: AppSpacing.sm,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 22,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (event.statusLabel != null && event.statusColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: event.statusColor!.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    event.statusLabel!,
                    style: AppTypography.badgeLabel.copyWith(color: event.statusColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radius10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.groups_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  '${event.participantCount} volunteers joined',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            event.isOrganizer
                ? 'You\'re organizing this action. Upload "after" photos once it\'s completed.'
                : 'Join the action to help clean this site.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          if (!event.isOrganizer) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => _navigateToEcoEvent(context, event),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  'Join action',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
