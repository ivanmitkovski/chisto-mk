import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/presentation/screens/notifications_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/pollution_site_card.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _FeedFilter {
  all('All sites', 'Show all pollution reports', Icons.grid_view_rounded),
  urgent('Urgent', 'Requires immediate attention', Icons.warning_amber_rounded),
  nearby('Nearby', 'Closest to you first', Icons.near_me_rounded),
  mostVoted('Most voted', 'By community support', Icons.trending_up_rounded),
  recent('Recent', 'Newest reports first', Icons.schedule_rounded);

  const _FeedFilter(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
}

class PollutionFeedScreen extends StatefulWidget {
  const PollutionFeedScreen({super.key});

  @override
  State<PollutionFeedScreen> createState() => _PollutionFeedScreenState();
}

class _PollutionFeedScreenState extends State<PollutionFeedScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<PollutionSite> _allSites = <PollutionSite>[];
  List<FeedNotification> _notifications = <FeedNotification>[];
  _FeedFilter _activeFilter = _FeedFilter.all;
  final ScrollController _scrollController = ScrollController();
  AnimationController? _entranceController;

  List<FeedNotification> _ensureNotificationsSeeded() {
    if (_notifications.isEmpty) {
      _notifications = _buildMockNotifications();
    }
    return _notifications;
  }

  List<PollutionSite> _ensureSitesSeeded() {
    if (_allSites.isEmpty) {
      _allSites = _buildMockSites();
    }
    return _allSites;
  }

  int get _unreadNotificationsCount =>
      _ensureNotificationsSeeded()
          .where((FeedNotification n) => !n.isRead)
          .length;

  List<PollutionSite> get _sites {
    final List<PollutionSite> source = _ensureSitesSeeded();
    switch (_activeFilter) {
      case _FeedFilter.all:
        return source;
      case _FeedFilter.urgent:
        return source.where((PollutionSite s) => s.urgencyLabel != null).toList();
      case _FeedFilter.nearby:
        return List<PollutionSite>.from(source)
          ..sort((PollutionSite a, PollutionSite b) => a.distanceKm.compareTo(b.distanceKm));
      case _FeedFilter.mostVoted:
        return List<PollutionSite>.from(source)
          ..sort((PollutionSite a, PollutionSite b) => b.score.compareTo(a.score));
      case _FeedFilter.recent:
        return source.reversed.toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _allSites = _buildMockSites();
    _notifications = _buildMockNotifications();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );

    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _entranceController?.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController?.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    // TODO: Wire this into real data loading once backend is available.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<void> scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: AppMotion.standard,
      curve: AppMotion.emphasized,
    );
  }

  Future<void> _openNotifications() async {
    AppHaptics.softTransition();
    final List<FeedNotification> currentNotifications =
        List<FeedNotification>.from(_ensureNotificationsSeeded());
    final List<FeedNotification>? updated =
        await Navigator.of(context).push<List<FeedNotification>>(
      MaterialPageRoute<List<FeedNotification>>(
        builder: (_) => NotificationsScreen(
          notifications: currentNotifications,
          availableSites: _ensureSitesSeeded(),
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _notifications = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topHotZoneHeight = MediaQuery.of(context).padding.top + 8;
    return Stack(
      children: <Widget>[
        RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.panelBackground,
          displacement: 72,
          edgeOffset: 0,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildSectionHeader(context)),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildSkeletonList())
              else if (_sites.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyFilterState(context),
                )
              else
                SliverList.builder(
                  itemCount: _sites.length,
                  itemBuilder: (BuildContext context, int index) {
                    final AnimationController? controller = _entranceController;
                    final Widget card = Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: PollutionSiteCard(site: _sites[index]),
                    );
                    if (controller == null) return card;
                    final double staggerDelay = (index * 0.15).clamp(0.0, 0.6);
                    final double staggerEnd = (staggerDelay + 0.4).clamp(0.0, 1.0);
                    final Animation<double> opacity = CurvedAnimation(
                      parent: controller,
                      curve: Interval(staggerDelay, staggerEnd, curve: AppMotion.standardCurve),
                    );
                    final Animation<Offset> slide = Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: controller,
                      curve: Interval(staggerDelay, staggerEnd, curve: AppMotion.emphasized),
                    ));
                    return FadeTransition(
                      opacity: opacity,
                      child: SlideTransition(
                        position: slide,
                        child: card,
                      ),
                    );
                  },
                ),
              if (!_isLoading && _sites.isNotEmpty)
                SliverToBoxAdapter(child: _buildFooter(context)),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          width: 112,
          height: topHotZoneHeight,
          child: Semantics(
            button: true,
            label: 'Scroll feed to top',
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                AppHaptics.tap();
                scrollToTop();
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          width: 112,
          height: topHotZoneHeight,
          child: Semantics(
            button: true,
            label: 'Scroll feed to top',
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                AppHaptics.tap();
                scrollToTop();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg - 4,
          AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 21,
                backgroundImage: AssetImage('assets/images/content/people_cleaning.png'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Hi, ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                      Text(
                        'John',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Explore pollution sites near you',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: -0.1,
                        ),
                  ),
                ],
              ),
            ),
            _FeedNotificationBell(
              unreadCount: _unreadNotificationsCount,
              onTap: _openNotifications,
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    AppHaptics.tap();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => _FilterSheet(
        activeFilter: _activeFilter,
        onSelected: (_FeedFilter filter) {
          if (filter != _activeFilter) {
            Navigator.of(context).pop();
            setState(() => _activeFilter = filter);
            scrollToTop();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              'Pollution sites',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Semantics(
            button: true,
            label: 'Filter feed',
            value: _activeFilter.label,
            child: GestureDetector(
              onTap: () => _openFilterSheet(context),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.emphasized,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _activeFilter == _FeedFilter.all
                      ? AppColors.panelBackground
                      : AppColors.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeFilter == _FeedFilter.all
                        ? AppColors.divider
                        : AppColors.primaryDark.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: _activeFilter == _FeedFilter.all
                      ? null
                      : <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _activeFilter.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _activeFilter == _FeedFilter.all
                                ? AppColors.textSecondary
                                : AppColors.primaryDark,
                            fontSize: 13,
                            letterSpacing: -0.1,
                          ),
                    ),
                    if (_activeFilter != _FeedFilter.all && _sites.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_sites.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _activeFilter == _FeedFilter.all
                          ? AppColors.textMuted
                          : AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You\u2019re all caught up',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull to refresh for new reports',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  String _getEmptyFilterMessage() {
    switch (_activeFilter) {
      case _FeedFilter.urgent:
        return 'No urgent sites right now';
      case _FeedFilter.nearby:
        return 'No nearby sites found';
      case _FeedFilter.mostVoted:
        return 'No sites have been voted yet';
      case _FeedFilter.recent:
        return 'No recent reports';
      case _FeedFilter.all:
        return 'No pollution sites yet';
    }
  }

  String _getEmptyFilterHint() {
    switch (_activeFilter) {
      case _FeedFilter.urgent:
      case _FeedFilter.nearby:
      case _FeedFilter.mostVoted:
      case _FeedFilter.recent:
        return 'Show all sites or try another filter';
      case _FeedFilter.all:
        return 'Pull to refresh or check back later';
    }
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.emphasized,
              switchOutCurve: AppMotion.emphasized,
              child: Container(
                key: ValueKey<_FeedFilter>(_activeFilter),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _activeFilter.icon,
                  size: 30,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _getEmptyFilterMessage(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _getEmptyFilterHint(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_activeFilter != _FeedFilter.all)
              FilledButton.tonal(
                onPressed: () {
                  AppHaptics.tap();
                  setState(() => _activeFilter = _FeedFilter.all);
                  scrollToTop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: const Text('Show all sites'),
              )
            else
              OutlinedButton(
                onPressed: () {
                  AppHaptics.tap();
                  _handleRefresh();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: const Text('Pull to refresh'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: List<Widget>.generate(
          3,
          (int index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == 2 ? 0 : AppSpacing.lg,
              ),
              child: _SkeletonCard(),
            );
          },
        ),
      ),
    );
  }

  List<FeedNotification> _buildMockNotifications() {
    final DateTime now = DateTime.now();
    return <FeedNotification>[
      FeedNotification(
        id: 'n1',
        title: 'New support on your report',
        message: '12 people upvoted "Illegal landfill near the river".',
        createdAt: now.subtract(const Duration(minutes: 18)),
        type: FeedNotificationType.update,
        isRead: false,
        targetSiteId: '1',
        targetTabIndex: 0,
      ),
      FeedNotification(
        id: 'n2',
        title: 'Cleanup event scheduled',
        message: 'Weekend eco action starts in 3 days. Tap to review details.',
        createdAt: now.subtract(const Duration(hours: 2)),
        type: FeedNotificationType.action,
        isRead: false,
        targetSiteId: '1',
        targetTabIndex: 1,
      ),
      FeedNotification(
        id: 'n3',
        title: 'Site status updated',
        message: 'Plastic waste in the park was changed to Low priority.',
        createdAt: now.subtract(const Duration(hours: 20)),
        type: FeedNotificationType.system,
        isRead: true,
        targetSiteId: '2',
        targetTabIndex: 0,
      ),
      FeedNotification(
        id: 'n4',
        title: 'Community comment',
        message: 'eco_maria commented on a site you follow.',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        type: FeedNotificationType.update,
        isRead: true,
        targetSiteId: '3',
        targetTabIndex: 0,
      ),
    ];
  }

  List<PollutionSite> _buildMockSites() {
    const ImageProvider image1 = AssetImage('assets/images/references/onboarding_reference.png');
    const ImageProvider image2 = AssetImage('assets/images/content/people_cleaning.png');

    final List<Comment> comments1 = <Comment>[
      const Comment(
        id: 'c1-1',
        authorName: 'eco_maria',
        text: 'Reported this last week. Hope it gets cleaned soon.',
        likeCount: 2,
      ),
      const Comment(
        id: 'c1-2',
        authorName: 'green_skopje',
        text: 'We could organize a cleanup here!',
        likeCount: 1,
      ),
      const Comment(
        id: 'c1-3',
        authorName: 'nature_lover',
        text: 'Same spot has been an issue for months.',
      ),
    ];
    final List<Comment> comments2 = <Comment>[
      const Comment(
        id: 'c2-1',
        authorName: 'park_volunteer',
        text: 'I can help with bags and gloves.',
      ),
    ];
    final List<Comment> comments3 = <Comment>[
      const Comment(
        id: 'c3-1',
        authorName: 'local_resident',
        text: 'This is right next to the playground.',
        likeCount: 3,
      ),
      const Comment(
        id: 'c3-2',
        authorName: 'clean_crew',
        text: 'Added to our list for next weekend.',
      ),
    ];

    final DateTime now = DateTime.now();
    final List<CleaningEvent> eventsForSite1 = <CleaningEvent>[
      CleaningEvent(
        id: 'e1',
        title: 'Weekend eco action',
        dateTime: now.add(const Duration(days: 3)),
        participantCount: 18,
        isOrganizer: true,
        statusLabel: 'Upcoming',
        statusColor: AppColors.primaryDark,
      ),
    ];

    return <PollutionSite>[
      PollutionSite(
        id: '1',
        title: 'Illegal landfill near the river',
        description:
            'Large pile of mixed waste accumulating near the riverside, attracting pests and polluting the water.',
        statusLabel: 'Medium',
        statusColor: AppColors.accentDanger,
        distanceKm: 15,
        score: 10,
        participantCount: 4,
        imageProvider: image1,
        images: <ImageProvider>[image1, image2],
        comments: comments1,
        urgencyLabel: 'Urgent',
        cleaningEvents: eventsForSite1,
      ),
      PollutionSite(
        id: '2',
        title: 'Plastic waste in the park',
        description:
            'Single-use plastics and bottles scattered across the city park pathways and playground.',
        statusLabel: 'Low',
        statusColor: AppColors.primary,
        distanceKm: 3,
        score: 6,
        participantCount: 2,
        imageProvider: image2,
        images: <ImageProvider>[image2, image1],
        comments: comments2,
      ),
      PollutionSite(
        id: '3',
        title: 'Construction debris dump',
        description:
            'Construction materials and rubble left in an empty lot close to a residential area.',
        statusLabel: 'High',
        statusColor: AppColors.accentDanger,
        distanceKm: 8,
        score: 18,
        participantCount: 7,
        imageProvider: image1,
        images: <ImageProvider>[image1, image2, image1],
        comments: comments3,
      ),
    ];
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.activeFilter,
    required this.onSelected,
  });

  final _FeedFilter activeFilter;
  final void Function(_FeedFilter) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter feed',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg + 16,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _FeedFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (BuildContext context, int index) {
                  final _FeedFilter filter = _FeedFilter.values[index];
                  final bool isActive = filter == activeFilter;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(filter),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primaryDark.withValues(alpha: 0.12)
                                    : AppColors.inputFill,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                filter.icon,
                                size: 20,
                                color: isActive
                                    ? AppColors.primaryDark
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    filter.label,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: isActive
                                          ? AppColors.primaryDark
                                          : AppColors.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    filter.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 24,
                                color: AppColors.primaryDark,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedNotificationBell extends StatefulWidget {
  const _FeedNotificationBell({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  State<_FeedNotificationBell> createState() => _FeedNotificationBellState();
}

class _FeedNotificationBellState extends State<_FeedNotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.unreadCount > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _FeedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unreadCount == 0 && widget.unreadCount > 0) {
      _pulseController.repeat(reverse: true);
    } else if (oldWidget.unreadCount > 0 && widget.unreadCount == 0) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = widget.unreadCount > 0;
    return Semantics(
      button: true,
      label: hasUnread
          ? 'Notifications, ${widget.unreadCount} unread'
          : 'Notifications, all read',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (hasUnread)
              Positioned.fill(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.12, end: 0.28).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: AppMotion.decelerate,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentDanger.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: hasUnread
                      ? <Color>[
                          const Color(0xFFFFFFFF),
                          const Color(0xFFFFF3F3),
                        ]
                      : <Color>[
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF8F9FB),
                        ],
                ),
                border: Border.all(
                  color: hasUnread
                      ? AppColors.accentDanger.withValues(alpha: 0.22)
                      : AppColors.divider,
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.notificationBing,
                  width: 21,
                  height: 21,
                  colorFilter: ColorFilter.mode(
                    hasUnread ? AppColors.accentDanger : AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                top: -2,
                right: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentDanger,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.panelBackground, width: 1.5),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.accentDanger.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                    ),
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: const <Color>[
                Color(0xFFEBECF0),
                Color(0xFFF5F6FA),
                Color(0xFFEBECF0),
              ],
              stops: <double>[
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value,
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child!,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(color: AppColors.inputFill),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _SkeletonBox(width: 28, height: 28, isCircle: true),
                      const SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 28, height: 28, isCircle: true),
                      const SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 28, height: 28, isCircle: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SkeletonLine(widthFactor: 0.55),
                  const SizedBox(height: AppSpacing.sm),
                  _SkeletonLine(widthFactor: 0.85),
                  const SizedBox(height: AppSpacing.xs),
                  _SkeletonLine(widthFactor: 0.65),
                  const SizedBox(height: AppSpacing.lg),
                  _SkeletonLine(widthFactor: 1.0, height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, this.height = 12});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(height > 20 ? 12 : 999),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.isCircle = false,
  });

  final double width;
  final double height;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(6),
      ),
    );
  }
}


