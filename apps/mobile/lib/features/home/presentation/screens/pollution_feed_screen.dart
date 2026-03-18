import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/notifications_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_header.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_section_header.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_skeleton.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/pollution_site_card.dart';
import 'package:chisto_mobile/features/home/data/mock_pollution_sites.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class PollutionFeedScreen extends StatefulWidget {
  const PollutionFeedScreen({super.key});

  @override
  State<PollutionFeedScreen> createState() => _PollutionFeedScreenState();
}

class _PollutionFeedScreenState extends State<PollutionFeedScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  AppError? _loadError;
  List<PollutionSite> _allSites = <PollutionSite>[];
  List<FeedNotification> _notifications = <FeedNotification>[];
  FeedFilter _activeFilter = FeedFilter.all;
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
      case FeedFilter.all:
        return source;
      case FeedFilter.urgent:
        return source.where((PollutionSite s) => s.urgencyLabel != null).toList();
      case FeedFilter.nearby:
        return List<PollutionSite>.from(source)
          ..sort((PollutionSite a, PollutionSite b) => a.distanceKm.compareTo(b.distanceKm));
      case FeedFilter.mostVoted:
        return List<PollutionSite>.from(source)
          ..sort((PollutionSite a, PollutionSite b) => b.score.compareTo(a.score));
      case FeedFilter.recent:
        return source.reversed.toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final List<PollutionSite> sites = _buildMockSites();
      final List<FeedNotification> notifications = _buildMockNotifications();
      setState(() {
        _allSites = sites;
        _notifications = notifications;
        _isLoading = false;
        _loadError = null;
      });
      _entranceController?.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = AppError.network(cause: e);
        _isLoading = false;
      });
      if (mounted) {
        AppSnack.show(
          context,
          message: 'No connection',
          type: AppSnackType.warning,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController?.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    await _loadFeed();
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
      CupertinoPageRoute<List<FeedNotification>>(
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
    final double topHotZoneHeight = MediaQuery.of(context).padding.top + AppSpacing.xs;
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
              SliverToBoxAdapter(
                child: FeedHeader(
                  displayName: ServiceLocator.instance.authState.displayName ?? 'You',
                  unreadCount: _unreadNotificationsCount,
                  onProfileTap: () {
                    AppHaptics.softTransition();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  onNotificationTap: _openNotifications,
                ),
              ),
              SliverToBoxAdapter(
                child: FeedSectionHeader(
                  activeFilter: _activeFilter,
                  sitesCount: _sites.length,
                  onFilterTap: () => _openFilterSheet(context),
                ),
              ),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildSkeletonList())
              else if (_loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorView(
                    error: _loadError!,
                    onRetry: _loadFeed,
                  ),
                )
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
              if (!_isLoading && _loadError == null && _sites.isNotEmpty)
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

  void _openFilterSheet(BuildContext context) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => FeedFilterSheet(
        activeFilter: _activeFilter,
        onSelected: (FeedFilter filter) {
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

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: AppSpacing.xl,
            height: AppSpacing.sheetHandleHeight,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
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
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Pull to refresh for new reports',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }

  String _getEmptyFilterMessage() {
    switch (_activeFilter) {
      case FeedFilter.urgent:
        return 'No urgent sites right now';
      case FeedFilter.nearby:
        return 'No nearby sites found';
      case FeedFilter.mostVoted:
        return 'No sites have been voted yet';
      case FeedFilter.recent:
        return 'No recent reports';
      case FeedFilter.all:
        return 'No pollution sites yet';
    }
  }

  String _getEmptyFilterHint() {
    switch (_activeFilter) {
      case FeedFilter.urgent:
      case FeedFilter.nearby:
      case FeedFilter.mostVoted:
      case FeedFilter.recent:
        return 'Show all sites or try another filter';
      case FeedFilter.all:
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
                key: ValueKey<FeedFilter>(_activeFilter),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
              style: AppTypography.emptyStateTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _getEmptyFilterHint(),
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateSubtitle.copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_activeFilter != FeedFilter.all)
              FilledButton.tonal(
                onPressed: () {
                  AppHaptics.tap();
                  setState(() => _activeFilter = FeedFilter.all);
                  scrollToTop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
              child: FeedSkeletonCard(),
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
    return buildMockPollutionSites();
  }
}
