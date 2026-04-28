import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/notifications_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_caught_up_footer.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_empty_state.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_bar.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_header.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_load_more_row.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_offline_banner.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_section_header.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_skeleton.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/presentation/providers/feed_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/pollution_site_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class PollutionFeedScreen extends ConsumerStatefulWidget {
  const PollutionFeedScreen({super.key});

  @override
  ConsumerState<PollutionFeedScreen> createState() => _PollutionFeedScreenState();
}

class _PollutionFeedScreenState extends ConsumerState<PollutionFeedScreen>
    with TickerProviderStateMixin {
  int _serverUnreadCount = 0;
  final ScrollController _scrollController = ScrollController();
  AnimationController? _entranceController;
  AnimationController? _skeletonController;
  bool _hasShownEntrance = false;
  List<PollutionSite> _ensureSitesSeeded(WidgetRef ref) =>
      ref.read(feedSitesNotifierProvider).allSites;

  int get _unreadNotificationsCount => _serverUnreadCount;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _skeletonController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    )..repeat();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadFeed());
      }
    });
  }

  Future<void> _loadFeed() async {
    await ref.read(feedSitesNotifierProvider.notifier).loadInitial();
    if (!mounted) {
      return;
    }
    unawaited(_refreshUnreadCount());
    if (!_hasShownEntrance &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _entranceController?.forward(from: 0);
    }
    _hasShownEntrance = true;
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
    final FeedSitesState feed = ref.read(feedSitesNotifierProvider);
    if (!_scrollController.hasClients ||
        feed.isLoadingMore ||
        feed.isLoading ||
        !feed.hasMore) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    final double viewport = MediaQuery.sizeOf(context).height;
    if (position.pixels < position.maxScrollExtent - viewport * 3) {
      return;
    }
    unawaited(_loadMoreFeed());
  }

  Future<void> _loadMoreFeed() async {
    final bool ok =
        await ref.read(feedSitesNotifierProvider.notifier).loadMore();
    if (!mounted || ok) {
      return;
    }
    final AppError? error =
        ref.read(feedSitesNotifierProvider.select((FeedSitesState s) => s.loadMoreError));
    AppSnack.show(
      context,
      message: error?.message ?? context.l10n.feedLoadMoreFailedSnack,
      type: AppSnackType.warning,
    );
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    final bool hadCachedSites =
        ref.read(feedSitesNotifierProvider).allSites.isNotEmpty;
    await _loadFeed();
    if (!mounted) {
      return;
    }
    final FeedSitesState after = ref.read(feedSitesNotifierProvider);
    if (after.loadError != null &&
        hadCachedSites &&
        after.allSites.isNotEmpty) {
      AppSnack.show(
        context,
        message: context.l10n.feedRefreshStaleSnack,
        type: AppSnackType.warning,
      );
    }
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
            NotificationsScreen(availableSites: _ensureSitesSeeded(ref)),
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
      final int count = await ref.read(notificationsRepositoryProvider).getUnreadCount();
      if (!mounted) return;
      setState(() {
        _serverUnreadCount = count;
      });
    } catch (_) {
      // Unread badge refresh is non-critical; avoid interruptive UI if it fails.
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FeedFilter>(
      feedFilterProvider,
      (FeedFilter? previous, FeedFilter next) {
        if (previous == null) {
          return;
        }
        if (feedServerFetchGroup(previous) != feedServerFetchGroup(next)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(ref.read(feedSitesNotifierProvider.notifier).loadInitial());
            unawaited(scrollToTop());
          });
        }
      },
    );
    final bool feedIsLoading =
        ref.watch(feedSitesNotifierProvider.select((FeedSitesState s) => s.isLoading));
    final AppError? feedLoadError =
        ref.watch(feedSitesNotifierProvider.select((FeedSitesState s) => s.loadError));
    final bool feedHasMore =
        ref.watch(feedSitesNotifierProvider.select((FeedSitesState s) => s.hasMore));
    final bool feedIsLoadingMore =
        ref.watch(feedSitesNotifierProvider.select((FeedSitesState s) => s.isLoadingMore));
    final bool feedLoadMoreFailed =
        ref.watch(feedSitesNotifierProvider.select((FeedSitesState s) => s.loadMoreFailed));
    final bool feedLocationAvailable = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.locationAvailable),
    );
    final List<PollutionSite> visibleSites = ref.watch(feedVisibleSitesProvider);
    final FeedFilter activeFilter = ref.watch(feedFilterProvider);
    final String feedSessionId = ref.watch(feedSessionIdProvider);
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
              const SliverToBoxAdapter(child: FeedOfflineBannerHost()),
              SliverToBoxAdapter(
                child:                 FeedHeader(
                  displayName: ServiceLocator.instance.authState.displayName ??
                      context.l10n.feedDisplayNameFallback,
                  unreadCount: _unreadNotificationsCount,
                  onProfileTap: () {
                    AppHaptics.softTransition();
                    Navigator.of(context, rootNavigator: true).push(
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
                  activeFilter: activeFilter,
                  sitesCount: visibleSites.length,
                  onFilterTap: () => _openFilterSheet(context),
                ),
              ),
              SliverToBoxAdapter(
                child: FeedFilterBar(
                  activeFilter: activeFilter,
                  onFilterSelected: (FeedFilter filter) {
                    if (filter == activeFilter) {
                      return;
                    }
                    unawaited(
                      ref.read(feedFilterProvider.notifier).setFilter(filter),
                    );
                    unawaited(scrollToTop());
                  },
                  onMoreFiltersTap: () => _openFilterSheet(context),
                ),
              ),
              if (feedIsLoading)
                SliverToBoxAdapter(child: _buildSkeletonList())
              else if (feedLoadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorView(
                    error: feedLoadError,
                    onRetry: _loadFeed,
                  ),
                )
              else if (visibleSites.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FeedEmptyState(
                    activeFilter: activeFilter,
                    locationAvailable: feedLocationAvailable,
                    onShowAllSites: () {
                      AppHaptics.tap();
                      unawaited(
                        ref
                            .read(feedFilterProvider.notifier)
                            .setFilter(FeedFilter.all),
                      );
                      unawaited(scrollToTop());
                    },
                    onRefresh: () {
                      AppHaptics.tap();
                      _handleRefresh();
                    },
                  ),
                )
              else
                SliverList.builder(
                  key: const PageStorageKey<String>('feed_list'),
                  findChildIndexCallback: (Key key) {
                    if (key is ValueKey<String>) {
                      final int i = visibleSites.indexWhere(
                        (PollutionSite s) => s.id == key.value,
                      );
                      return i >= 0 ? i : null;
                    }
                    return null;
                  },
                  itemCount: visibleSites.length +
                      ((feedIsLoadingMore || feedLoadMoreFailed) ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= visibleSites.length) {
                      return FeedLoadMoreRow(
                        loadFailed: feedLoadMoreFailed,
                        onRetry: _loadMoreFeed,
                      );
                    }
                    final AnimationController? controller = _entranceController;
                    final Widget card = RepaintBoundary(
                      key: ValueKey<String>(visibleSites[index].id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: PollutionSiteCard(
                          site: visibleSites[index],
                          feedSessionId: feedSessionId,
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
              if (!feedIsLoading &&
                  feedLoadError == null &&
                  visibleSites.isNotEmpty &&
                  !feedHasMore)
                const SliverToBoxAdapter(child: FeedCaughtUpFooter()),
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
            label: context.l10n.feedScrollToTopSemantic,
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
            label: context.l10n.feedScrollToTopSemantic,
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
      builder: (BuildContext sheetContext) => FeedFilterSheet(
        activeFilter: ref.read(feedFilterProvider),
        onSelected: (FeedFilter filter) {
          if (filter != ref.read(feedFilterProvider)) {
            Navigator.of(sheetContext).pop();
            unawaited(
              ref.read(feedFilterProvider.notifier).setFilter(filter),
            );
            scrollToTop();
          } else {
            Navigator.of(sheetContext).pop();
          }
        },
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

  void _hideSiteFromFeed(String siteId) {
    ref.read(feedSitesNotifierProvider.notifier).removeSite(siteId);
  }
}
