import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/providers/site_history_providers.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_empty_state.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_footer.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_sections.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_skeleton.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_status_header.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_rows.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SiteHistoryTab extends ConsumerStatefulWidget {
  const SiteHistoryTab({super.key, required this.site});

  final PollutionSite site;

  @override
  ConsumerState<SiteHistoryTab> createState() => _SiteHistoryTabState();
}

class _SiteHistoryTabState extends ConsumerState<SiteHistoryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(siteHistoryProvider(widget.site.id).notifier).loadInitial();
    });
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
    if (error.code == 'NOT_FOUND') {
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
    final SiteHistoryState state = ref.read(
      siteHistoryProvider(widget.site.id),
    );
    if (!state.hasMore || state.isLoadingMore) return;
    ref.read(siteHistoryProvider(widget.site.id).notifier).loadMore();
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

  String _phaseKey(SiteHistoryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return 'loading';
    }
    if (state.error != null && state.items.isEmpty) {
      return 'error';
    }
    if (state.items.isEmpty) {
      return 'empty';
    }
    return 'loaded';
  }

  Widget _phaseChild(BuildContext context, SiteHistoryState state) {
    switch (_phaseKey(state)) {
      case 'loading':
        return const SiteHistorySkeleton();
      case 'error':
        final AppError error = state.error is AppError
            ? state.error! as AppError
            : AppError.unknown(cause: state.error);
        final AppError displayError = _historyDisplayError(context.l10n, error);
        return AppErrorView(
          error: displayError,
          retryFootnote: context.l10n.siteHistoryRetry,
          onRetry: () => ref
              .read(siteHistoryProvider(widget.site.id).notifier)
              .loadInitial(),
        );
      case 'empty':
        return const SiteHistoryEmptyState();
      default:
        final List<SiteHistoryTimelineRow> rows = buildSiteHistoryTimelineRows(
          items: state.items,
          now: DateTime.now(),
          sectionLabelFor: (SiteHistorySection section) =>
              siteHistorySectionLabel(context, section),
        );
        final DateTime? mostRecent = state.items.isEmpty
            ? null
            : state.items.first.occurredAt;

        return AppRefreshIndicator(
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
                    summary: state.summary,
                    entryCount: state.items.length,
                    mostRecentEntryAt: mostRecent,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (BuildContext context, int index) {
                    final SiteHistoryTimelineRow row = rows[index];
                    switch (row.kind) {
                      case SiteHistoryTimelineRowKind.sectionHeader:
                        return SiteHistoryTimelineSectionHeader(
                          key: ValueKey<String>('history-section-${row.label}'),
                          label: row.label!,
                          showLineAbove: row.showLineAbove,
                          showLineBelow: row.showLineBelow,
                        );
                      case SiteHistoryTimelineRowKind.entry:
                        return SiteHistoryTimelineTile(
                          key: ValueKey<String>(
                            'history-entry-${row.entry!.id}',
                          ),
                          entry: row.entry!,
                          showLineAbove: row.showLineAbove,
                          showLineBelow: row.showLineBelow,
                        );
                    }
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SiteHistoryFooter(mode: _footerMode(state)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SiteHistoryState state = ref.watch(
      siteHistoryProvider(widget.site.id),
    );

    return AnimatedPhaseSwitcher(
      phaseKey: _phaseKey(state),
      child: _phaseChild(context, state),
    );
  }
}
