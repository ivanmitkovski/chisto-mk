import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_home/src/domain/models/cleaning_event.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/sticky_bottom_cta.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CleaningEventsTab extends StatefulWidget {
  const CleaningEventsTab({
    super.key,
    required this.site,
    required this.onCreateEvent,
  });

  final PollutionSite site;
  final VoidCallback onCreateEvent;

  @override
  State<CleaningEventsTab> createState() => _CleaningEventsTabState();
}

class _CleaningEventsTabState extends State<CleaningEventsTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;
  EventsRepository? _eventsRepository;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: AppMotion.slow);
    final EventsRepository store = readEventsRepository();
    _eventsRepository = store;
    store.addListener(_onEventsRepositoryChanged);
    store.loadInitialIfNeeded();
    unawaited(store.prefetchEventsForSite(widget.site.id));
  }

  void _onEventsRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.syncRepeatingShimmer(_shimmer, context);
  }

  @override
  void dispose() {
    _eventsRepository?.removeListener(_onEventsRepositoryChanged);
    _shimmer.dispose();
    super.dispose();
  }

  Widget _buildLoadingSkeleton(BuildContext context, double ctaHeight) {
    return Semantics(
      key: const Key('cleaning-events-loading-semantics'),
      label: context.l10n.homeSiteCleaningLoadingSemantic,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (BuildContext context, Widget? child) {
            final double t = _shimmer.value;
            return Stack(
              children: <Widget>[
                CustomScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        ctaHeight + AppSpacing.md,
                      ),
                      sliver: SliverList.separated(
                        itemCount: 3,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, int index) =>
                            _CleaningEventCardSkeleton(
                              key: Key('cleaning-events-skeleton-card-$index'),
                              t: t,
                              showJoinButton: index != 1,
                            ),
                      ),
                    ),
                  ],
                ),
                _StickyBottomCtaSkeleton(t: t),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final double ctaHeight = 56 + AppSpacing.md * 2 + bottomSafe;
    final EventsRepository store = readEventsRepository();

    if (!store.isReady) {
      return _buildLoadingSkeleton(context, ctaHeight);
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
                      child:
                          store.lastGlobalListLoadFailed &&
                              !store.isShowingStaleCachedEvents
                          ? _buildLoadErrorState(context, store)
                          : _buildEmptyState(context),
                    )
                  : SliverList.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (BuildContext ctx, int i) =>
                          _buildEventCard(ctx, events[i]),
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
  }

  Widget _buildLoadErrorState(BuildContext context, EventsRepository store) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.homeSiteCleaningListLoadError,
              textAlign: TextAlign.center,
              style: AppTypographySurfaces.homeCleaningErrorBody(
                Theme.of(context).textTheme,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: context.l10n.homeSiteCleaningRetry,
              onPressed: () {
                store.loadInitialIfNeeded();
                unawaited(store.refreshEvents());
                unawaited(store.prefetchEventsForSite(widget.site.id));
              },
              expand: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppEmptyState(
      icon: Icons.groups_rounded,
      title: context.l10n.homeSiteCleaningEmptyTitle,
      subtitle: context.l10n.homeSiteCleaningEmptyBody,
      padding: const EdgeInsets.all(AppSpacing.lg),
      action: AppButton.text(
        label: context.l10n.homeSiteCleaningTapToCreate,
        onPressed: widget.onCreateEvent,
      ),
    );
  }

  void _navigateToEcoEvent(BuildContext context, CleaningEvent event) {
    final EventsRepository store = readEventsRepository();
    store.loadInitialIfNeeded();
    final EcoEvent? match = store.findById(event.id);
    if (match != null) {
      EventsNavigation.openDetail(context, eventId: match.id);
      return;
    }
    AppSnack.show(
      context,
      message: context.l10n.homeSiteCleaningEventUnavailable,
      type: AppSnackType.warning,
    );
  }

  BoxDecoration _eventCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.panelBackground,
      borderRadius: AppRadii.r18,
      boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
      border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
    );
  }

  Widget _buildEventCard(BuildContext context, CleaningEvent event) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String dateLabel = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(event.dateTime);

    return Semantics(
      button: true,
      label: '${event.title}, $dateLabel',
      child: GestureDetector(
        onTap: () => _navigateToEcoEvent(context, event),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: _eventCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        event.statusLabel!,
                        style: AppTypography.badgeLabel(
                          textTheme,
                        ).copyWith(color: event.statusColor),
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
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.homeSiteCleaningVolunteersJoined(
                        event.participantCount,
                      ),
                      style:
                          AppTypographySurfaces.homeCleaningEventsVolunteerCount(
                            Theme.of(context).textTheme,
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
                style: AppTypographySurfaces.homeCleaningEventsHint(
                  Theme.of(context).textTheme,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (!event.isOrganizer) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                if (event.isJoined)
                  AppButton.secondary(
                    label: context.l10n.homeSiteCleaningJoinedAction,
                    enabled: false,
                    expand: true,
                  )
                else
                  AppButton.primary(
                    label: context.l10n.homeSiteCleaningJoinAction,
                    onPressed: () => _navigateToEcoEvent(context, event),
                    expand: true,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CleaningEventCardSkeleton extends StatelessWidget {
  const _CleaningEventCardSkeleton({
    super.key,
    required this.t,
    required this.showJoinButton,
  });

  final double t;
  final bool showJoinButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppRadii.r18,
        boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _ShimmerBox(
                width: 40,
                height: 40,
                radius: AppSpacing.radiusMd,
                t: t,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ShimmerBox(
                      width: 136,
                      height: 15,
                      radius: AppSpacing.radiusSm,
                      t: t,
                    ),
                    const SizedBox(height: 6),
                    _ShimmerBox(
                      width: 88,
                      height: 12,
                      radius: AppSpacing.radiusSm,
                      t: t,
                    ),
                  ],
                ),
              ),
              _ShimmerBox(
                width: 76,
                height: 22,
                radius: AppSpacing.radiusPill,
                t: t,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ShimmerBox(
            width: 168,
            height: 28,
            radius: AppSpacing.radius10,
            t: t,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ShimmerBox(
            width: double.infinity,
            height: 12,
            radius: AppSpacing.radiusSm,
            t: t,
          ),
          const SizedBox(height: 6),
          _ShimmerBox(
            width: 216,
            height: 12,
            radius: AppSpacing.radiusSm,
            t: t,
          ),
          if (showJoinButton) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _ShimmerBox(
              width: double.infinity,
              height: 48,
              radius: AppSpacing.radiusMd,
              t: t,
            ),
          ],
        ],
      ),
    );
  }
}

class _StickyBottomCtaSkeleton extends StatelessWidget {
  const _StickyBottomCtaSkeleton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const Key('cleaning-events-skeleton-cta'),
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.appBackground,
          boxShadow: AppShadows.sheet(Theme.of(context).colorScheme),
        ),
        child: _ShimmerBox(
          width: double.infinity,
          height: 48,
          radius: AppSpacing.radiusMd,
          t: t,
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.t,
  });

  final double width;
  final double height;
  final double radius;
  final double t;

  @override
  Widget build(BuildContext context) {
    final double opacity = 0.06 + 0.04 * (0.5 + 0.5 * (1 - (2 * t - 1).abs()));
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
