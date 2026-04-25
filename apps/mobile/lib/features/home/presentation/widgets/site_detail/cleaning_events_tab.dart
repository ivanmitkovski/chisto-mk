import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_card_skeleton.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/sticky_bottom_cta.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class CleaningEventsTab extends StatefulWidget {
  const CleaningEventsTab({super.key, required this.site, required this.onCreateEvent});

  final PollutionSite site;
  final VoidCallback onCreateEvent;

  @override
  State<CleaningEventsTab> createState() => _CleaningEventsTabState();
}

class _CleaningEventsTabState extends State<CleaningEventsTab> {
  @override
  void initState() {
    super.initState();
    final EventsRepository store = EventsRepositoryRegistry.instance;
    store.loadInitialIfNeeded();
    unawaited(store.prefetchEventsForSite(widget.site.id));
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const EventCardSkeleton(),
            SizedBox(height: AppSpacing.md, child: Divider(height: 1, color: colorScheme.outlineVariant)),
            const EventCardSkeleton(),
            SizedBox(height: AppSpacing.md, child: Divider(height: 1, color: colorScheme.outlineVariant)),
            const EventCardSkeleton(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final double ctaHeight = 56 + AppSpacing.md * 2 + bottomSafe;
    final EventsRepository store = EventsRepositoryRegistry.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? child) {
        if (!store.isReady) {
          return _buildLoadingSkeleton(context);
        }
        final List<CleaningEvent> events = EventSiteResolver.cleaningEventsForSite(
          siteId: widget.site.id,
          events: store.events,
          statusLabelFor: (EcoEventStatus s) => s.localizedLabel(context.l10n),
        );
        return Stack(
          children: <Widget>[
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    ctaHeight + AppSpacing.md,
                  ),
                  sliver: events.isEmpty
                      ? SliverToBoxAdapter(
                          child: store.lastGlobalListLoadFailed && !store.isShowingStaleCachedEvents
                              ? _buildLoadErrorState(context, store)
                              : _buildEmptyState(context),
                        )
                      : SliverList.separated(
                          itemCount: events.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (BuildContext ctx, int i) => _buildEventCard(ctx, events[i]),
                        ),
                ),
              ],
            ),
            StickyBottomCTA(
              label: events.isEmpty
                  ? context.l10n.homeSiteCleaningCtaCreateFirst
                  : context.l10n.homeSiteCleaningCtaScheduleAnother,
              onPressed: widget.onCreateEvent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadErrorState(BuildContext context, EventsRepository store) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.homeSiteCleaningListLoadError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () {
                AppHaptics.tap();
                store.loadInitialIfNeeded();
                unawaited(store.refreshEvents());
                unawaited(store.prefetchEventsForSite(widget.site.id));
              },
              child: Text(context.l10n.homeSiteCleaningRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          widget.onCreateEvent();
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
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.homeSiteCleaningEmptyTitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.homeSiteCleaningEmptyBody,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.homeSiteCleaningTapToCreate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
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
      message: context.l10n.homeSiteCleaningEventUnavailable,
      type: AppSnackType.warning,
    );
  }

  Widget _buildEventCard(BuildContext context, CleaningEvent event) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String dateLabel =
        DateFormat.yMd(Localizations.localeOf(context).toString()).format(event.dateTime);

    return Semantics(
      button: true,
      label: '${event.title}, $dateLabel',
      child: GestureDetector(
        onTap: () => _navigateToEcoEvent(context, event),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
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
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 22,
                      color: colorScheme.primary,
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
                                color: colorScheme.onSurface,
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
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radius10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.groups_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.homeSiteCleaningVolunteersJoined(event.participantCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                event.isOrganizer
                    ? context.l10n.homeSiteCleaningOrganizerHint
                    : context.l10n.homeSiteCleaningVolunteerHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
              if (!event.isOrganizer) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _navigateToEcoEvent(context, event),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      context.l10n.homeSiteCleaningJoinAction,
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
      ),
    );
  }
}
