import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_radii.dart';
import 'package:chisto_mobile/core/theme/app_shadows.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_history_providers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_date_section_header.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_empty_state.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_footer.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_grouped_panel.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_list_tile.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_sections.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_skeleton.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_status_header.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_error_view.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SiteHistoryTab extends ConsumerStatefulWidget {
  const SiteHistoryTab({super.key, required this.site});

  final PollutionSite site;

  @override
  ConsumerState<SiteHistoryTab> createState() => _SiteHistoryTabState();
}

class _SiteHistoryTabState extends ConsumerState<SiteHistoryTab> {
  static const int _lazySectionEntryThreshold = 8;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  AppError _historyDisplayError(AppLocalizations l10n, AppError error) {
    if (error.code == 'SITE_NOT_FOUND') {
      return AppError(
        code: 'SITE_NOT_FOUND',
        message: l10n.feedSiteNotFoundMessage,
      );
    }
    final String message = error.message;
    if (error.code == 'NOT_FOUND' &&
        message.contains('Cannot GET') &&
        message.contains('/history')) {
      return AppError(
        code: 'NOT_FOUND',
        message: l10n.siteHistoryServiceUnavailable,
      );
    }
    return error;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset < max - 200) return;
    final SiteHistoryState state = ref.read(siteHistoryProvider(widget.site.id));
    if (!state.hasMore || state.isLoadingMore) return;
    ref.read(siteHistoryProvider(widget.site.id).notifier).loadMore();
  }

  List<Widget> _buildSectionSlivers(
    BuildContext context,
    List<SiteHistoryEntry> items,
  ) {
    final List<SiteHistorySection> sections =
        groupSiteHistoryByBucket(items, DateTime.now());
    final List<Widget> slivers = <Widget>[];

    for (final SiteHistorySection section in sections) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SiteHistorySectionLabel(
              label: siteHistorySectionLabel(context, section),
            ),
          ),
        ),
      );
      if (section.entries.length > _lazySectionEntryThreshold) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.builder(
              itemCount: section.entries.length,
              itemBuilder: (BuildContext context, int index) {
                final bool isFirst = index == 0;
                final bool isLast = index == section.entries.length - 1;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: isFirst && isLast
                        ? AppRadii.r18
                        : BorderRadius.vertical(
                            top: isFirst
                                ? const Radius.circular(AppSpacing.radius18)
                                : Radius.zero,
                            bottom: isLast
                                ? const Radius.circular(AppSpacing.radius18)
                                : Radius.zero,
                          ),
                    boxShadow: isFirst
                        ? AppShadows.panel(Theme.of(context).colorScheme)
                        : null,
                    border: Border(
                      left: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.9),
                      ),
                      right: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.9),
                      ),
                      top: isFirst
                          ? BorderSide(
                              color: AppColors.divider.withValues(alpha: 0.9),
                            )
                          : BorderSide.none,
                      bottom: isLast
                          ? BorderSide(
                              color: AppColors.divider.withValues(alpha: 0.9),
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: SiteHistoryListTile(
                    entry: section.entries[index],
                    showDividerBelow: !isLast,
                  ),
                );
              },
            ),
          ),
        );
      } else {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SiteHistoryGroupedPanel(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < section.entries.length; i++)
                      SiteHistoryListTile(
                        entry: section.entries[i],
                        showDividerBelow: i < section.entries.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    return slivers;
  }

  SiteHistoryFooterMode _footerMode(SiteHistoryState state) {
    if (state.isLoadingMore) {
      return SiteHistoryFooterMode.loadingMore;
    }
    if (!state.hasMore && state.items.isNotEmpty) {
      return SiteHistoryFooterMode.endOfList;
    }
    return SiteHistoryFooterMode.none;
  }

  @override
  Widget build(BuildContext context) {
    final SiteHistoryState state = ref.watch(siteHistoryProvider(widget.site.id));

    if (state.isLoading && state.items.isEmpty) {
      return const AnimatedSwitcher(
        duration: AppMotion.fast,
        child: SiteHistorySkeleton(key: ValueKey<String>('skeleton')),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      final AppError error = state.error is AppError
          ? state.error! as AppError
          : AppError.unknown(cause: state.error);
      final AppError displayError = _historyDisplayError(context.l10n, error);
      return AppErrorView(
        error: displayError,
        retryFootnote: context.l10n.siteHistoryRetry,
        onRetry: () =>
            ref.read(siteHistoryProvider(widget.site.id).notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return const SiteHistoryEmptyState();
    }

    final DateTime mostRecent = state.items.first.occurredAt;

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: AppRefreshIndicator(
        key: const ValueKey<String>('loaded'),
        onRefresh: () =>
            ref.read(siteHistoryProvider(widget.site.id).notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: SiteHistoryStatusHeader(
                  site: widget.site,
                  entryCount: state.items.length,
                  mostRecentEntryAt: mostRecent,
                ),
              ),
            ),
            ..._buildSectionSlivers(context, state.items),
            SliverToBoxAdapter(
              child: SiteHistoryFooter(mode: _footerMode(state)),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }
}
