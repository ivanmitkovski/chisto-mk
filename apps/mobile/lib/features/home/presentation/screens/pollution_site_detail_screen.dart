import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_bottom_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen.dart';

class PollutionSiteDetailScreen extends StatelessWidget {
  const PollutionSiteDetailScreen({
    super.key,
    required this.site,
    this.initialTabIndex = 0,
  });

  final PollutionSite site;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex.clamp(0, 1),
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        body: Column(
          children: <Widget>[
            _buildHeader(context),
            _buildTabs(context),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _PollutionSiteTab(
                    site: site,
                    onTakeAction: () => _openTakeActionDialog(context),
                  ),
                  _CleaningEventsTab(
                    site: site,
                    onCreateEvent: () async {
                      AppHaptics.softTransition();
                      final EcoEvent? createdEvent = await EventsNavigation.openCreate(
                        context,
                        preselectedSiteId: site.id,
                        preselectedSiteName: site.title,
                        preselectedSiteImageUrl:
                            'assets/images/references/onboarding_reference.png',
                        preselectedSiteDistanceKm: site.distanceKm.toDouble(),
                      );
                      if (createdEvent == null || !context.mounted) {
                        return;
                      }
                      await EventsNavigation.openDetail(
                        context,
                        eventId: createdEvent.id,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTakeActionDialog(BuildContext context) async {
    AppHaptics.medium();
    final String? action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.panelBackground,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: const TakeActionBottomSheet(),
        );
      },
    );
    if (action == null || !context.mounted) return;
    if (action == 'Report Issue') {
      AppHaptics.softTransition();
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => NewReportScreen(
            entryLabel: 'Site follow-up',
            entryHint:
                'Use this to report new evidence or changes for ${site.title}.',
          ),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Row(
          children: <Widget>[
            const AppBackButton(),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                site.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () {
                AppHaptics.tap();
                // TODO: Share site.
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.cardShare,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        indicatorColor: AppColors.primaryDark,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        tabs: const <Widget>[
          Tab(text: 'Pollution site'),
          Tab(text: 'Cleaning events'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pollution site tab
// ---------------------------------------------------------------------------

class _PollutionSiteTab extends StatelessWidget {
  const _PollutionSiteTab({required this.site, required this.onTakeAction});

  final PollutionSite site;
  final VoidCallback onTakeAction;

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final double ctaHeight = 56 + AppSpacing.md * 2 + bottomSafe;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DetailHeroCarousel(site: site),
              const SizedBox(height: AppSpacing.md),
              _buildStatsRow(context),
              const SizedBox(height: AppSpacing.md),
              Text(
                site.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                site.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildReportedRow(context),
              const SizedBox(height: AppSpacing.lg),
              _buildInfoCard(context),
              const SizedBox(height: AppSpacing.md),
              _buildQuickActions(context),
            ],
          ),
        ),
        _StickyBottomCTA(label: 'Take action', onPressed: onTakeAction),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: <Widget>[
        _StatChip(
          iconWidget: SvgPicture.asset(
            AppAssets.cardArrowUp,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.primaryDark,
              BlendMode.srcIn,
            ),
          ),
          label: '+${site.score}',
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          iconWidget: SvgPicture.asset(
            AppAssets.cardComments,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.textMuted,
              BlendMode.srcIn,
            ),
          ),
          label: '${site.commentCount}',
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          iconWidget: const Icon(
            Icons.groups_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          label: '${site.participantCount}',
          color: AppColors.textMuted,
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.place_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 3),
            Text(
              '${site.distanceKm.toStringAsFixed(0)} km',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportedRow(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
              children: const <TextSpan>[
                TextSpan(text: 'Reported by '),
                TextSpan(
                  text: 'eco_maria',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(text: '  •  2 days ago'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 20,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Community action needed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join a cleanup, report changes, or help spread the word so we can act faster.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickActionTile(
            icon: CupertinoIcons.bookmark,
            label: 'Save site',
            onTap: () {
              AppHaptics.tap();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionTile(
            icon: CupertinoIcons.flag,
            label: 'Report issue',
            onTap: () {
              AppHaptics.tap();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionTile(
            icon: CupertinoIcons.share,
            label: 'Share',
            onTap: () {
              AppHaptics.tap();
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cleaning events tab
// ---------------------------------------------------------------------------

class _CleaningEventsTab extends StatelessWidget {
  const _CleaningEventsTab({required this.site, required this.onCreateEvent});

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
            _StickyBottomCTA(
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
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
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
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Be the first to organize an eco action\nand rally volunteers for this site.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
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
                  borderRadius: BorderRadius.circular(12),
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
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: event.statusColor!.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.statusLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: event.statusColor,
                    ),
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
              borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Join action',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _StickyBottomCTA extends StatelessWidget {
  const _StickyBottomCTA({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: PrimaryButton(label: label, onPressed: onPressed),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.iconWidget,
    required this.label,
    required this.color,
  });

  final Widget iconWidget;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconWidget,
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero image carousel
// ---------------------------------------------------------------------------

class _DetailHeroCarousel extends StatelessWidget {
  const _DetailHeroCarousel({required this.site});

  final PollutionSite site;

  @override
  Widget build(BuildContext context) {
    final List<GalleryImageItem> items = List<GalleryImageItem>.generate(
      site.galleryImages.length,
      (int index) => GalleryImageItem(
        image: site.galleryImages[index],
        heroTag: 'site-image-${site.id}-$index',
        semanticLabel: 'Pollution site photo ${index + 1}',
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ImmersivePhotoGallery(
        items: items,
        borderRadius: 24,
        openLabel: 'Open pollution site gallery',
        topLeftBuilder:
            (BuildContext context, int currentIndex, int totalCount) {
              return GalleryGlassPill(
                emphasis: GalleryGlassPillEmphasis.strong,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: site.statusColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      site.statusLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
        bottomCenterBuilder:
            (BuildContext context, int currentIndex, int totalCount) {
              return GalleryGlassPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.sparkles,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      totalCount > 1 ? 'Tap to expand' : 'Open photo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              );
            },
      ),
    );
  }
}
