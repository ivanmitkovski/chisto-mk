import 'dart:async';
import 'dart:math' as math;

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
import 'package:chisto_mobile/features/home/presentation/widgets/feed_stale_banner.dart';
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
  ConsumerState<PollutionFeedScreen> createState() =>
      _PollutionFeedScreenState();
}

class _PollutionFeedScreenState extends ConsumerState<PollutionFeedScreen>
    with TickerProviderStateMixin {
  /// A few dp past the status inset for hit tolerance; keep small to avoid covering
  /// the first sliver (aligns with iOS “tap status bar” — that region only).
  static const double _scrollToTopTapSlopPx = 6.0;
  /// Only when the OS reports almost no top inset (e.g. some tablets / edge cases).
  static const double _scrollToTopTapMinWhenInsetTiny = 32.0;
  static const double _scrollToTopTapTinyInsetThreshold = 16.0;

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
    _scrollController.addListener(_maybeLoadMoreFeed);
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
    _scrollController.removeListener(_maybeLoadMoreFeed);
    _scrollController.dispose();
    _entranceController?.dispose();
    _skeletonController?.dispose();
    super.dispose();
  }

  void _maybeLoadMoreFeed() {
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

  void _openProfile() {
    AppHaptics.softTransition();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _handleFilterSelection(FeedFilter filter) {
    if (filter == ref.read(feedFilterProvider)) {
      return;
    }
    unawaited(ref.read(feedFilterProvider.notifier).setFilter(filter));
    unawaited(scrollToTop());
  }

  Future<void> _loadMoreFeed() async {
    final bool ok = await ref
        .read(feedSitesNotifierProvider.notifier)
        .loadMore();
    if (!mounted || ok) {
      return;
    }
    final AppError? error = ref.read(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.loadMoreError),
    );
    AppSnack.show(
      context,
      message: error?.message ?? context.l10n.feedLoadMoreFailedSnack,
      type: AppSnackType.warning,
    );
  }

  /// Shared by [RefreshIndicator], empty state retry, and any future triggers.
  Future<void> _performFeedRefresh() async {
    AppHaptics.medium();
    final bool hadCachedSites = ref
        .read(feedSitesNotifierProvider)
        .allSites
        .isNotEmpty;
    await _loadFeed();
    if (!mounted) {
      return;
    }
    final FeedSitesState after = ref.read(feedSitesNotifierProvider);
    bool showedStaleSnack = false;
    if (after.loadError != null &&
        hadCachedSites &&
        after.allSites.isNotEmpty) {
      showedStaleSnack = true;
      AppSnack.show(
        context,
        message: context.l10n.feedRefreshStaleSnack,
        type: AppSnackType.warning,
      );
    }
    if (!showedStaleSnack) {
      AppHaptics.light(context);
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
      final int count = await ref
          .read(notificationsRepositoryProvider)
          .getUnreadCount();
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
    ref.listen<FeedFilter>(feedFilterProvider, (
      FeedFilter? previous,
      FeedFilter next,
    ) {
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
    });
    final bool feedIsLoading = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.isLoading),
    );
    final FeedSitesViewStatus feedStatus = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.status),
    );
    final AppError? feedLoadError = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.loadError),
    );
    final bool feedHasMore = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.hasMore),
    );
    final bool feedIsLoadingMore = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.isLoadingMore),
    );
    final bool feedLoadMoreFailed = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.loadMoreFailed),
    );
    final bool feedLocationAvailable = ref.watch(
      feedSitesNotifierProvider.select(
        (FeedSitesState s) => s.locationAvailable,
      ),
    );
    final bool feedIsStaleFallback =
        feedStatus == FeedSitesViewStatus.staleData;
    final List<PollutionSite> visibleSites = ref.watch(
      feedVisibleSitesProvider,
    );
    final FeedFilter activeFilter = ref.watch(feedFilterProvider);
    final String feedSessionId = ref.watch(feedSessionIdProvider);
    final String displayName =
        ref.watch(homeAuthStateProvider).displayName ??
        context.l10n.feedDisplayNameFallback;
    final String feedVariant = ref.watch(
      feedSitesNotifierProvider.select((FeedSitesState s) => s.feedVariant),
    );
    final MediaQueryData mq = MediaQuery.of(context);
    final MediaQueryData windowMq = MediaQueryData.fromView(View.of(context));
    final double statusInset = math.max(
      windowMq.viewPadding.top,
      math.max(mq.viewPadding.top, mq.padding.top),
    ).clamp(0.0, 120.0);
    final double scrollToTopTapStripHeight = () {
      final double withSlop = statusInset + _scrollToTopTapSlopPx;
      if (statusInset < _scrollToTopTapTinyInsetThreshold) {
        return math.max(withSlop, _scrollToTopTapMinWhenInsetTiny);
      }
      return withSlop;
    }().clamp(0.0, 100.0);
    final Color feedBackground =
        Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: feedBackground,
      body: ColoredBox(
        color: feedBackground,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
          SafeArea(
            top: true,
            bottom: false,
            left: false,
            right: false,
            child: RefreshIndicator(
              onRefresh: _performFeedRefresh,
              color: AppColors.primary,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  const SliverToBoxAdapter(child: FeedOfflineBannerHost()),
                  SliverToBoxAdapter(
                    child: FeedHeader(
                      displayName: displayName,
                      unreadCount: _unreadNotificationsCount,
                      onProfileTap: _openProfile,
                      onNotificationTap: _openNotifications,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FeedSectionHeader(),
                  ),
                  SliverToBoxAdapter(
                    child: FeedFilterBar(
                      activeFilter: activeFilter,
                      onFilterSelected: _handleFilterSelection,
                      onMoreFiltersTap: () => _openFilterSheet(context),
                    ),
                  ),
                  if (feedIsStaleFallback)
                    const SliverToBoxAdapter(child: FeedStaleBanner()),
                  if (feedIsLoading)
                    SliverToBoxAdapter(child: _buildSkeletonList())
                  else if (feedLoadError != null &&
                      feedStatus == FeedSitesViewStatus.firstLoadError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child:
                          AppErrorView(error: feedLoadError, onRetry: _loadFeed),
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
                          unawaited(_performFeedRefresh());
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
                        final AnimationController? controller =
                            _entranceController;
                        final Widget card = RepaintBoundary(
                          key: ValueKey<String>(visibleSites[index].id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: PollutionSiteCard(
                              site: visibleSites[index],
                              feedSessionId: feedSessionId,
                              feedVariant: feedVariant,
                              onHidden: _hideSiteFromFeed,
                            ),
                          ),
                        );
                        if (controller == null) return card;
                        final double staggerDelay =
                            (index * 0.15).clamp(0.0, 0.6);
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
                        final Animation<Offset> slide = Tween<Offset>(
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
          ),
          if (scrollToTopTapStripHeight > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: scrollToTopTapStripHeight,
              child: Semantics(
                button: true,
                label: context.l10n.feedScrollToTopSemantic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptics.tap();
                    unawaited(scrollToTop());
                  },
                  child: ColoredBox(color: feedBackground),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext sheetContext) => FeedFilterSheet(
        activeFilter: ref.read(feedFilterProvider),
        onSelected: (FeedFilter filter) {
          if (filter != ref.read(feedFilterProvider)) {
            Navigator.of(sheetContext).pop();
            unawaited(ref.read(feedFilterProvider.notifier).setFilter(filter));
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
