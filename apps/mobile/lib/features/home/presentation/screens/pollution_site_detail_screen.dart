import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_bottom_sheet.dart';

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
                    onCreateEvent: () => _openTakeActionDialog(context),
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
    await showDialog<String>(
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
  const _PollutionSiteTab({
    required this.site,
    required this.onTakeAction,
  });

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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
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
        _StickyBottomCTA(
          label: 'Take action',
          onPressed: onTakeAction,
        ),
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
          iconWidget: const Icon(Icons.groups_rounded, size: 16, color: AppColors.textMuted),
          label: '${site.participantCount}',
          color: AppColors.textMuted,
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.place_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(
              '${site.distanceKm.toStringAsFixed(0)} km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                  ),
              children: const <TextSpan>[
                TextSpan(
                  text: 'Reported by ',
                ),
                TextSpan(
                  text: 'eco_maria',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
            child: const Icon(Icons.eco_rounded, size: 20, color: AppColors.primaryDark),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
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
  const _CleaningEventsTab({
    required this.site,
    required this.onCreateEvent,
  });

  final PollutionSite site;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final List<CleaningEvent> events = site.cleaningEvents;
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (events.isEmpty)
                _buildEmptyState(context)
              else
                ...events.map((CleaningEvent event) => _buildEventCard(context, event)),
            ],
          ),
        ),
        _StickyBottomCTA(
          label: events.isEmpty ? 'Create eco action' : 'Schedule another action',
          onPressed: onCreateEvent,
        ),
      ],
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
            child: const Icon(Icons.groups_rounded, size: 32, color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No cleaning events yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Be the first to organize an eco action\nand rally volunteers for this site.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CleaningEvent event) {
    final String dateLabel =
        '${event.dateTime.day.toString().padLeft(2, '0')}.${event.dateTime.month.toString().padLeft(2, '0')}.${event.dateTime.year}';

    return Container(
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
                child: const Icon(Icons.eco_rounded, size: 22, color: AppColors.primaryDark),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (event.statusLabel != null && event.statusColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.groups_rounded, size: 16, color: AppColors.primaryDark),
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
                onPressed: () {
                  AppHaptics.medium();
                  // TODO: Join event flow.
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
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
// Fullscreen image gallery viewer
// ---------------------------------------------------------------------------

class _FullscreenGalleryScreen extends StatefulWidget {
  const _FullscreenGalleryScreen({
    required this.images,
    required this.initialIndex,
    required this.heroTag,
  });

  final List<ImageProvider> images;
  final int initialIndex;
  final String heroTag;

  @override
  State<_FullscreenGalleryScreen> createState() => _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState extends State<_FullscreenGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  double _verticalDrag = 0;
  double _opacity = 1.0;
  bool _didPrefetchImages = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefetchImages) return;
    _didPrefetchImages = true;
    for (int i = 0; i < widget.images.length && i < 3; i++) {
      precacheImage(widget.images[i], context);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalDrag += details.delta.dy;
      _opacity = (1.0 - (_verticalDrag.abs() / 300)).clamp(0.4, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_verticalDrag.abs() > 100 ||
        (details.primaryVelocity != null && details.primaryVelocity!.abs() > 600)) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _verticalDrag = 0;
        _opacity = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedContainer(
          duration: _verticalDrag == 0 ? AppMotion.medium : Duration.zero,
          curve: AppMotion.emphasized,
          color: Colors.black.withValues(alpha: _opacity),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _verticalDrag),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.images.length,
                      onPageChanged: (int index) {
                        AppHaptics.tap();
                        setState(() => _currentIndex = index);
                        _prefetchAround(index);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final Widget image = AppSmartImage(
                          image: widget.images[index],
                          fit: BoxFit.contain,
                        );
                        if (index == widget.initialIndex) {
                          return Hero(
                            tag: widget.heroTag,
                            child: image,
                          );
                        }
                        return image;
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.md,
                  child: Semantics(
                    button: true,
                    label: 'Close full-screen gallery',
                    child: GestureDetector(
                      onTap: () {
                        AppHaptics.tap();
                        Navigator.of(context).pop();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.images.length > 1)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (widget.images.length > 1)
                  Positioned(
                    bottom: AppSpacing.xl,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(widget.images.length, (int index) {
                          final bool isActive = index == _currentIndex;
                          return AnimatedContainer(
                            duration: AppMotion.fast,
                            curve: AppMotion.emphasized,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _prefetchAround(int index) {
    final int previous = index - 1;
    final int next = index + 1;
    if (previous >= 0 && previous < widget.images.length) {
      precacheImage(widget.images[previous], context);
    }
    if (next >= 0 && next < widget.images.length) {
      precacheImage(widget.images[next], context);
    }
  }
}

// ---------------------------------------------------------------------------
// Hero image carousel
// ---------------------------------------------------------------------------

class _DetailHeroCarousel extends StatefulWidget {
  const _DetailHeroCarousel({required this.site});

  final PollutionSite site;

  @override
  State<_DetailHeroCarousel> createState() => _DetailHeroCarouselState();
}

class _DetailHeroCarouselState extends State<_DetailHeroCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _didPrefetchImages = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefetchImages) return;
    _didPrefetchImages = true;
    final List<ImageProvider> images = widget.site.galleryImages;
    for (int i = 0; i < images.length && i < 3; i++) {
      precacheImage(images[i], context);
    }
  }

  void _openFullscreen(BuildContext context) {
    AppHaptics.tap();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return _FullscreenGalleryScreen(
            images: widget.site.galleryImages,
            initialIndex: _currentIndex,
            heroTag: 'site-image-${widget.site.id}',
          );
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppMotion.medium,
        reverseTransitionDuration: AppMotion.fast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ImageProvider> images = widget.site.galleryImages;

    return Semantics(
      image: true,
      label: 'Photos of pollution site. Tap to view fullscreen.',
      child: GestureDetector(
        onTap: () => _openFullscreen(context),
        child: Hero(
          tag: 'site-image-${widget.site.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (int index) {
                      setState(() => _currentIndex = index);
                      _prefetchAround(index, images);
                    },
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return SizedBox.expand(
                        child: AppSmartImage(image: images[index]),
                      );
                    },
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.site.statusColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.site.statusLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_currentIndex + 1}/${images.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Bottom pager bars removed on detail hero; the top-right
                  // counter already communicates image position and keeps this
                  // area visually cleaner during feed->detail transition.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _prefetchAround(int index, List<ImageProvider> images) {
    final int previous = index - 1;
    final int next = index + 1;
    if (previous >= 0 && previous < images.length) {
      precacheImage(images[previous], context);
    }
    if (next >= 0 && next < images.length) {
      precacheImage(images[next], context);
    }
  }
}
