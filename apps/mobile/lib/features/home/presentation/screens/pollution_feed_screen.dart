import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
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
import 'package:chisto_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class PollutionFeedScreen extends StatefulWidget {
  const PollutionFeedScreen({super.key});

  @override
  State<PollutionFeedScreen> createState() => _PollutionFeedScreenState();
}

class _PollutionFeedScreenState extends State<PollutionFeedScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  AppError? _loadError;
  List<PollutionSite> _allSites = <PollutionSite>[];
  List<PollutionSite> _visibleSites = <PollutionSite>[];
  int _serverUnreadCount = 0;
  FeedFilter _activeFilter = FeedFilter.all;
  final ScrollController _scrollController = ScrollController();
  AnimationController? _entranceController;
  AnimationController? _skeletonController;
  double? _userLatitude;
  double? _userLongitude;
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  bool _hasShownEntrance = false;
  bool _locationAvailable = true;
  late final String _feedSessionId;

  List<PollutionSite> _ensureSitesSeeded() => _allSites;

  int get _unreadNotificationsCount => _serverUnreadCount;

  List<PollutionSite> _computeVisibleSites() {
    final List<PollutionSite> source = _ensureSitesSeeded();
    switch (_activeFilter) {
      case FeedFilter.all:
        return List<PollutionSite>.from(source);
      case FeedFilter.urgent:
        final urgent = source
            .where((PollutionSite s) => s.urgencyLabel != null)
            .toList();
        if (urgent.isNotEmpty) return urgent;
        final fallback = List<PollutionSite>.from(source)
          ..sort((a, b) {
            final scoreA = _statusPriority(a.statusLabel);
            final scoreB = _statusPriority(b.statusLabel);
            if (scoreA != scoreB) return scoreB.compareTo(scoreA);
            return b.commentsCount.compareTo(a.commentsCount);
          });
        return fallback;
      case FeedFilter.nearby:
        return List<PollutionSite>.from(source)
          ..sort((PollutionSite a, PollutionSite b) {
            final bool aKnown = a.distanceKm >= 0;
            final bool bKnown = b.distanceKm >= 0;
            if (aKnown != bKnown) return aKnown ? -1 : 1;
            if (!aKnown && !bKnown) return b.score.compareTo(a.score);
            return a.distanceKm.compareTo(b.distanceKm);
          });
      case FeedFilter.mostVoted:
        return List<PollutionSite>.from(source)..sort((
          PollutionSite a,
          PollutionSite b,
        ) {
          final supportA = a.score + (a.commentsCount * 3) + (a.shareCount * 4);
          final supportB = b.score + (b.commentsCount * 3) + (b.shareCount * 4);
          return supportB.compareTo(supportA);
        });
      case FeedFilter.recent:
        return List<PollutionSite>.from(
          source,
        )..sort((a, b) => (b.rankingScore ?? 0).compareTo(a.rankingScore ?? 0));
    }
  }

  @override
  void initState() {
    super.initState();
    final String userId = ServiceLocator.instance.authState.userId ?? 'anon';
    _feedSessionId = 'feed_${DateTime.now().millisecondsSinceEpoch}_$userId';
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _skeletonController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    )..repeat();
    _scrollController.addListener(_onScroll);
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    try {
      await _resolveUserLocation();
      final result = await ServiceLocator.instance.sitesRepository.getSites(
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: 100,
        status: 'VERIFIED',
        page: 1,
        limit: 24,
        mode: 'for_you',
        sort: 'hybrid',
        explain: true,
      );
      if (!mounted) return;
      unawaited(_refreshUnreadCount());
      setState(() {
        _allSites = result.sites;
        _visibleSites = _computeVisibleSites();
        _nextCursor = result.nextCursor;
        _hasMore = result.nextCursor?.isNotEmpty ?? false;
        _isLoadingMore = false;
        _loadMoreFailed = false;
        _isLoading = false;
        _loadError = null;
      });
      if (!_hasShownEntrance &&
          !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
        _entranceController?.forward(from: 0);
      }
      _hasShownEntrance = true;
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = AppError.network(cause: e);
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveUserLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _userLatitude = null;
        _userLongitude = null;
        _locationAvailable = false;
        return;
      }
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _userLatitude = null;
        _userLongitude = null;
        _locationAvailable = false;
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _userLatitude = position.latitude;
      _userLongitude = position.longitude;
      _locationAvailable = true;
    } catch (_) {
      _userLatitude = null;
      _userLongitude = null;
      _locationAvailable = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _entranceController?.dispose();
    _skeletonController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        _isLoading ||
        !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 640) return;
    _loadMoreFeed();
  }

  Future<void> _loadMoreFeed() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });
    try {
      final result = await ServiceLocator.instance.sitesRepository.getSites(
        latitude: _userLatitude,
        longitude: _userLongitude,
        radiusKm: 100,
        status: 'VERIFIED',
        page: 1,
        limit: 24,
        mode: 'for_you',
        sort: 'hybrid',
        explain: true,
        cursor: _nextCursor,
      );
      if (!mounted) return;
      final mergedById = <String, PollutionSite>{
        for (final site in _allSites) site.id: site,
      };
      for (final site in result.sites) {
        mergedById[site.id] = site;
      }
      setState(() {
        _allSites = mergedById.values.toList();
        _visibleSites = _computeVisibleSites();
        _nextCursor = result.nextCursor;
        _hasMore = result.nextCursor?.isNotEmpty ?? false;
        _loadMoreFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadMoreFailed = true;
      });
      AppSnack.show(
        context,
        message: 'Could not load more posts. Tap retry.',
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
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
    final int? unreadAfter = await Navigator.of(context).push<int>(
      CupertinoPageRoute<int>(
        builder: (_) =>
            NotificationsScreen(availableSites: _ensureSitesSeeded()),
      ),
    );
    if (!mounted) return;
    if (unreadAfter != null) {
      setState(() {
        _serverUnreadCount = unreadAfter;
      });
    }
    unawaited(_refreshUnreadCount());
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final int count = await ServiceLocator.instance.notificationsRepository
          .getUnreadCount();
      if (!mounted) return;
      setState(() {
        _serverUnreadCount = count;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final double topHotZoneHeight =
        MediaQuery.of(context).padding.top + AppSpacing.xs;
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
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: FeedHeader(
                  displayName:
                      ServiceLocator.instance.authState.displayName ?? 'You',
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
                  sitesCount: _visibleSites.length,
                  onFilterTap: () => _openFilterSheet(context),
                ),
              ),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildSkeletonList())
              else if (_loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorView(error: _loadError!, onRetry: _loadFeed),
                )
              else if (_visibleSites.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyFilterState(context),
                )
              else
                SliverList.builder(
                  itemCount:
                      _visibleSites.length +
                      ((_isLoadingMore || _loadMoreFailed) ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= _visibleSites.length) {
                      if (_loadMoreFailed) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: _loadMoreFeed,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry loading more'),
                            ),
                          ),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final AnimationController? controller = _entranceController;
                    final Widget card = RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: PollutionSiteCard(
                          site: _visibleSites[index],
                          feedSessionId: _feedSessionId,
                          onHidden: _hideSiteFromFeed,
                        ),
                      ),
                    );
                    if (controller == null) return card;
                    final double staggerDelay = (index * 0.15).clamp(0.0, 0.6);
                    final double staggerEnd = (staggerDelay + 0.4).clamp(
                      0.0,
                      1.0,
                    );
                    final Animation<double> opacity = CurvedAnimation(
                      parent: controller,
                      curve: Interval(
                        staggerDelay,
                        staggerEnd,
                        curve: AppMotion.standardCurve,
                      ),
                    );
                    final Animation<Offset> slide =
                        Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: controller,
                            curve: Interval(
                              staggerDelay,
                              staggerEnd,
                              curve: AppMotion.emphasized,
                            ),
                          ),
                        );
                    return FadeTransition(
                      opacity: opacity,
                      child: SlideTransition(position: slide, child: card),
                    );
                  },
                ),
              if (!_isLoading &&
                  _loadError == null &&
                  _visibleSites.isNotEmpty &&
                  !_hasMore)
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
            setState(() {
              _activeFilter = filter;
              _visibleSites = _computeVisibleSites();
            });
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
        return _locationAvailable
            ? 'No nearby sites found'
            : 'Enable location to see nearby sites';
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
        if (!_locationAvailable) {
          return 'Turn on location services and allow access';
        }
        return 'Show all sites or try another filter';
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
                  _emptyFilterIcon(_activeFilter),
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
                  backgroundColor: AppColors.primaryDark.withValues(
                    alpha: 0.12,
                  ),
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
    final AnimationController? controller = _skeletonController;
    if (controller == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: List<Widget>.generate(3, (int index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == 2 ? 0 : AppSpacing.lg,
                ),
                child: FeedSkeletonCard(shimmerT: controller.value),
              );
            }),
          ),
        );
      },
    );
  }

  IconData _emptyFilterIcon(FeedFilter filter) {
    switch (filter) {
      case FeedFilter.all:
        return Icons.filter_alt_outlined;
      case FeedFilter.urgent:
        return Icons.warning_amber_rounded;
      case FeedFilter.nearby:
        return Icons.near_me_rounded;
      case FeedFilter.mostVoted:
        return Icons.trending_up_rounded;
      case FeedFilter.recent:
        return Icons.schedule_rounded;
    }
  }

  int _statusPriority(String statusLabel) {
    final normalized = statusLabel.toLowerCase();
    if (normalized.contains('reported')) return 4;
    if (normalized.contains('verified')) return 3;
    if (normalized.contains('in progress')) return 2;
    if (normalized.contains('cleanup')) return 1;
    return 0;
  }

  void _hideSiteFromFeed(String siteId) {
    setState(() {
      _allSites = _allSites.where((s) => s.id != siteId).toList();
      _visibleSites = _computeVisibleSites();
    });
  }
}
