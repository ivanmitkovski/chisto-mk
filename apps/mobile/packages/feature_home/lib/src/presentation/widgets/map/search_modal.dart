import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_recent_queries_shelf.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/providers/map_derived_providers.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/providers/map_search_controller.dart';
import 'package:feature_home/src/presentation/utils/map_search_highlight.dart';
import 'package:feature_home/src/presentation/utils/map_site_filter.dart';
import 'package:feature_home/src/presentation/widgets/map/map_pollution_type_ui.dart';
import 'package:feature_home/src/presentation/widgets/map/map_search_modal_controller.dart';
import 'package:feature_home/src/presentation/widgets/map/map_search_suggestions_section.dart';
import 'package:feature_home/src/presentation/widgets/map/map_site_pin_image.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapSearchModal extends ConsumerStatefulWidget {
  const MapSearchModal({
    super.key,
    required this.onResultTap,
    required this.onDismiss,
    this.onGeoIntentSelected,
  });

  final ValueChanged<PollutionSite> onResultTap;
  final VoidCallback onDismiss;
  final ValueChanged<SiteMapSearchGeoIntent>? onGeoIntentSelected;

  @override
  ConsumerState<MapSearchModal> createState() => _MapSearchModalState();
}

class _MapSearchModalState extends ConsumerState<MapSearchModal> {
  static const int _emptyPreviewLimit = 8;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final MapSearchModalController _modalController;

  MapSearchController get _searchNotifier =>
      ref.read(mapSearchControllerProvider.notifier);

  List<String> get _recents => _modalController.recents;

  Future<void> _refreshRecents() async {
    await _modalController.refreshRecents();
  }

  void _onQueryChanged() => _searchNotifier.updateQuery(_controller.text);

  void _applyQuery(String query) {
    _controller.text = query;
    _searchNotifier.updateQuery(query);
  }

  Future<void> _persistRecentQuery(String query) async {
    await _modalController.persistRecentQuery(query);
  }

  Future<void> _onSuggestionTap(String query) async {
    _applyQuery(query);
    await _persistRecentQuery(query);
  }

  Future<void> _onGeoIntentTap(SiteMapSearchGeoIntent intent) async {
    await _modalController.onGeoIntentTap(
      intent: intent,
      queryText: _controller.text,
      onSelected: (SiteMapSearchGeoIntent selected) {
        widget.onGeoIntentSelected?.call(selected);
      },
    );
  }

  void _onSearchSubmitted() {
    final MapSearchState state = ref.read(mapSearchControllerProvider);
    final PollutionSite? first = _modalController.firstSearchResult(state);
    if (first != null) {
      unawaited(_onSiteSelected(first));
      return;
    }
    _focusNode.unfocus();
  }

  List<PollutionSite> _previewSites(List<PollutionSite> pool) =>
      _modalController.previewSites(pool, limit: _emptyPreviewLimit);

  void _clearQuery() {
    _controller.clear();
    _searchNotifier.clearQuery();
  }

  Future<void> _onSiteSelected(PollutionSite site) async {
    await _persistRecentQuery(_controller.text);
    widget.onResultTap(site);
  }

  Future<void> _clearRecents() async {
    await _modalController.clearRecents();
  }

  @override
  void initState() {
    super.initState();
    _modalController = MapSearchModalController(
      onRecentsChanged: (_) {
        if (mounted) setState(() {});
      },
    );
    unawaited(_refreshRecents());
    _controller.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MapSearchState state = ref.watch(mapSearchControllerProvider);
    final List<PollutionSite> previewPool = ref.watch(
      mapSearchLocalPoolProvider,
    );
    final MapFilterState filter = ref.watch(mapFilterNotifierProvider);

    final bool isCompact = MediaQuery.sizeOf(context).width < 400;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ReportSheetScaffold(
      title: context.l10n.mapSearchSheetTitle,
      useModalRouteShape: true,
      addBottomInset: true,
      fillAvailableHeight: true,
      // Overlay keyboard model: keep the sheet full height and let the scroll
      // body pad once via appSheetOverlayKeyboardInset. Shrinking here too would
      // double-count the inset and collapse the results above the keyboard.
      shrinkForKeyboard: false,
      maxHeightFactor: 1,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      trailing: ReportCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: context.l10n.semanticClose,
        onTap: widget.onDismiss,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: AppCupertinoSearchField(
                controller: _controller,
                focusNode: _focusNode,
                placeholder: context.l10n.searchModalPlaceholder,
                semanticLabel: context.l10n.searchModalPlaceholder,
                semanticHint: context.l10n.mapSearchFieldSemanticHint,
                autocorrect: false,
                textStyle: AppTypographySurfaces.homeSearchFieldText(textTheme),
                placeholderStyle:
                    AppTypographySurfaces.homeSearchFieldPlaceholder(textTheme),
                onSubmitted: _onSearchSubmitted,
                onClear: _clearQuery,
              ),
            ),
            _MapSearchStatusRow(
              state: state,
              onRetry: _searchNotifier.retryRemote,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double keyboardInset = math.min(
                    appSheetOverlayKeyboardInset(context),
                    constraints.maxHeight,
                  );
                  return Padding(
                    padding: EdgeInsets.only(bottom: keyboardInset),
                    child: _MapSearchScrollBody(
                      state: state,
                      recents: _recents,
                      previewSites: _previewSites(previewPool),
                      filter: filter,
                      isCompact: isCompact,
                      scrollController: _scrollController,
                      onQueryTap: _applyQuery,
                      onSuggestionTap: _onSuggestionTap,
                      onClearRecents: _clearRecents,
                      onResetFilters: () {
                        ref
                            .read(mapFilterNotifierProvider.notifier)
                            .resetAllFilters();
                      },
                      onRetry: _searchNotifier.retryRemote,
                      onGeoIntentSelected: widget.onGeoIntentSelected == null
                          ? null
                          : _onGeoIntentTap,
                      onSiteSelected: _onSiteSelected,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSearchStatusRow extends StatelessWidget {
  const _MapSearchStatusRow({required this.state, required this.onRetry});

  final MapSearchState state;
  final VoidCallback onRetry;

  String? _semanticLabel(BuildContext context) {
    if (state.isSearching) {
      return context.l10n.mapSearchSemanticSearching;
    }
    if (state.shouldShowNoResults) {
      return context.l10n.mapSearchSemanticNoResults;
    }
    if (state.hasQuery && state.totalMatchCount > 0) {
      return context.l10n.mapSearchSemanticResults(state.totalMatchCount);
    }
    final bool hasRemoteError = state.remotePhase == MapSearchRemotePhase.error;
    final bool showResults =
        state.hasQuery &&
        (state.localResults.isNotEmpty || state.remoteOnlyResults.isNotEmpty);
    if (hasRemoteError && showResults) {
      return context.l10n.mapSearchSemanticRemoteError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool showResults =
        state.hasQuery &&
        (state.localResults.isNotEmpty || state.remoteOnlyResults.isNotEmpty);
    final bool showBadge = state.hasQuery && state.totalMatchCount > 0;
    final bool showSearchProgress = state.isSearching;
    final bool hasRemoteError = state.remotePhase == MapSearchRemotePhase.error;
    final bool showInlineRemoteError = hasRemoteError && showResults;

    if (!showBadge && !showSearchProgress && !showInlineRemoteError) {
      final String? semantic = _semanticLabel(context);
      if (semantic == null) {
        return const SizedBox.shrink();
      }
      return Semantics(
        liveRegion: true,
        label: semantic,
        child: const SizedBox.shrink(),
      );
    }

    return Semantics(
      liveRegion: true,
      label: _semanticLabel(context),
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (showBadge)
              Align(
                alignment: Alignment.centerLeft,
                child: AppStatusPill(
                  label: context.l10n.mapSearchResultsBadge(
                    state.totalMatchCount,
                  ),
                  tone: AppSurfaceTone.accent,
                  dense: true,
                  emphasized: true,
                ),
              ),
            if (showSearchProgress) ...<Widget>[
              if (showBadge) const SizedBox(height: AppSpacing.xs),
              const AppLinearProgress(),
            ],
            if (showInlineRemoteError) ...<Widget>[
              if (showBadge || showSearchProgress)
                const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.mapSearchRemoteError,
                      style: AppTypographySurfaces.homeMutedCaption(
                        Theme.of(context).textTheme,
                      ).copyWith(color: AppColors.error),
                    ),
                  ),
                  AppButton.text(
                    label: context.l10n.mapSearchRemoteRetry,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _MapSearchListEntryKind { sectionHeader, divider, site }

class _MapSearchListEntry {
  const _MapSearchListEntry._({required this.kind, this.title, this.site});

  const _MapSearchListEntry.section(String title)
    : this._(kind: _MapSearchListEntryKind.sectionHeader, title: title);

  const _MapSearchListEntry.divider()
    : this._(kind: _MapSearchListEntryKind.divider);

  const _MapSearchListEntry.site(PollutionSite site)
    : this._(kind: _MapSearchListEntryKind.site, site: site);

  final _MapSearchListEntryKind kind;
  final String? title;
  final PollutionSite? site;
}

class _MapSearchScrollBody extends StatelessWidget {
  const _MapSearchScrollBody({
    required this.state,
    required this.recents,
    required this.previewSites,
    required this.filter,
    required this.isCompact,
    required this.scrollController,
    required this.onQueryTap,
    required this.onSuggestionTap,
    required this.onClearRecents,
    required this.onResetFilters,
    required this.onRetry,
    required this.onGeoIntentSelected,
    required this.onSiteSelected,
  });

  final MapSearchState state;
  final List<String> recents;
  final List<PollutionSite> previewSites;
  final MapFilterState filter;
  final bool isCompact;
  final ScrollController scrollController;
  final ValueChanged<String> onQueryTap;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onClearRecents;
  final VoidCallback onResetFilters;
  final VoidCallback onRetry;
  final ValueChanged<SiteMapSearchGeoIntent>? onGeoIntentSelected;
  final ValueChanged<PollutionSite> onSiteSelected;

  List<_MapSearchListEntry> _listEntries({
    required String onMapTitle,
    required String everywhereTitle,
  }) {
    final List<_MapSearchListEntry> entries = <_MapSearchListEntry>[];

    void addSites(List<PollutionSite> sites, String sectionTitle) {
      if (sites.isEmpty) {
        return;
      }
      entries.add(_MapSearchListEntry.section(sectionTitle));
      for (int i = 0; i < sites.length; i++) {
        if (i > 0) {
          entries.add(const _MapSearchListEntry.divider());
        }
        entries.add(_MapSearchListEntry.site(sites[i]));
      }
    }

    addSites(state.localResults, onMapTitle);
    addSites(state.remoteOnlyResults, everywhereTitle);
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final bool showResults =
        state.hasQuery &&
        (state.localResults.isNotEmpty || state.remoteOnlyResults.isNotEmpty);
    final bool showEmptyQuery = !state.hasQuery;
    final bool showQueryTooShort =
        state.isQueryTooShortForRemote && !showResults;
    final bool hasRemoteError = state.remotePhase == MapSearchRemotePhase.error;
    final bool showRemoteErrorBody = hasRemoteError && !showResults;
    final bool showNoResults = state.shouldShowNoResults;
    final bool showFiltersReset =
        showNoResults && mapFilterHasNonDefault(filter);
    const EdgeInsets shelfPadding = EdgeInsets.only(bottom: AppSpacing.sm);
    final List<_MapSearchListEntry> entries = showResults
        ? _listEntries(
            onMapTitle: context.l10n.mapSearchSectionOnMap,
            everywhereTitle: context.l10n.mapSearchSectionEverywhere,
          )
        : const <_MapSearchListEntry>[];
    final List<_MapSearchListEntry> previewEntries = showEmptyQuery
        ? _previewEntries(previewSites, context.l10n.mapSearchSectionOnMap)
        : const <_MapSearchListEntry>[];

    return CustomScrollView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: <Widget>[
        if (showEmptyQuery && recents.isNotEmpty)
          SliverToBoxAdapter(
            child: AppRecentQueriesShelf(
              title: context.l10n.mapSearchRecentsLabel,
              queries: recents,
              onQueryTap: onQueryTap,
              onClear: onClearRecents,
              clearLabel: context.l10n.mapSearchClearRecentsButton,
              semanticLabelForQuery: (String query) =>
                  context.l10n.mapSearchRecentChipSemantic(query),
              padding: shelfPadding,
            ),
          ),
        if (showEmptyQuery && previewEntries.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.xs,
              0,
              AppSpacing.sm,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final _MapSearchListEntry entry = previewEntries[index];
                switch (entry.kind) {
                  case _MapSearchListEntryKind.sectionHeader:
                    return _SectionHeader(
                      title: entry.title!,
                      compact: isCompact,
                    );
                  case _MapSearchListEntryKind.divider:
                    return Divider(
                      height: 1,
                      color: AppColors.divider.withValues(alpha: 0.35),
                    );
                  case _MapSearchListEntryKind.site:
                    return _SearchResultTile(
                      site: entry.site!,
                      query: state.query,
                      onTap: () => onSiteSelected(entry.site!),
                      compact: isCompact,
                    );
                }
              }, childCount: previewEntries.length),
            ),
          ),
        if (showEmptyQuery && previewSites.isEmpty && recents.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.map_rounded,
              title: context.l10n.mapSearchEmptyTitle,
              subtitle: context.l10n.mapSearchEmptySubtitle,
            ),
          ),
        if (state.hasQuery &&
            (state.suggestions.isNotEmpty ||
                (state.geoIntent != null && onGeoIntentSelected != null)))
          SliverToBoxAdapter(
            child: MapSearchSuggestionsSection(
              suggestions: state.suggestions,
              query: state.query,
              geoIntent: state.geoIntent,
              onSuggestionTap: onSuggestionTap,
              onGeoIntentTap: onGeoIntentSelected,
              padding: shelfPadding,
            ),
          ),
        if (showResults)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.xs,
              0,
              AppSpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final _MapSearchListEntry entry = entries[index];
                switch (entry.kind) {
                  case _MapSearchListEntryKind.sectionHeader:
                    return _SectionHeader(
                      title: entry.title!,
                      compact: isCompact,
                    );
                  case _MapSearchListEntryKind.divider:
                    return Divider(
                      height: 1,
                      color: AppColors.divider.withValues(alpha: 0.35),
                    );
                  case _MapSearchListEntryKind.site:
                    return _SearchResultTile(
                      site: entry.site!,
                      query: state.query,
                      onTap: () => onSiteSelected(entry.site!),
                      compact: isCompact,
                    );
                }
              }, childCount: entries.length),
            ),
          )
        else if (showQueryTooShort)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.keyboard_outlined,
              title: context.l10n.mapSearchMinQueryTitle,
              subtitle: context.l10n.mapSearchMinQuerySubtitle,
            ),
          )
        else if (showRemoteErrorBody)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.cloud_off_outlined,
              title: context.l10n.mapSearchRemoteError,
              action: AppButton.text(
                label: context.l10n.mapSearchRemoteRetry,
                onPressed: onRetry,
              ),
            ),
          )
        else if (showNoResults)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.search_off_rounded,
              title: context.l10n.mapSearchNoResultsTitle,
              subtitle: context.l10n.mapSearchNoResultsSubtitle,
              action: showFiltersReset
                  ? AppButton.text(
                      label: context.l10n.mapSearchNoResultsResetFilters,
                      onPressed: onResetFilters,
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  List<_MapSearchListEntry> _previewEntries(
    List<PollutionSite> sites,
    String sectionTitle,
  ) {
    if (sites.isEmpty) {
      return const <_MapSearchListEntry>[];
    }
    final List<_MapSearchListEntry> entries = <_MapSearchListEntry>[
      _MapSearchListEntry.section(sectionTitle),
    ];
    for (int i = 0; i < sites.length; i++) {
      if (i > 0) {
        entries.add(const _MapSearchListEntry.divider());
      }
      entries.add(_MapSearchListEntry.site(sites[i]));
    }
    return entries;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      padding: EdgeInsets.fromLTRB(
        0,
        compact ? AppSpacing.sm : AppSpacing.md,
        0,
        AppSpacing.xs,
      ),
      titleStyle:
          AppTypographySurfaces.homeSheetSectionLabel(
            Theme.of(context).textTheme,
          ).copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.site,
    required this.query,
    required this.onTap,
    this.compact = false,
  });

  final PollutionSite site;
  final String query;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double thumbSize = compact ? 48 : 52;
    final TextStyle baseTitle = AppTypography.cardTitle(
      textTheme,
    ).copyWith(fontSize: 16);
    final TextStyle emphasis = baseTitle.copyWith(fontWeight: FontWeight.w700);
    final String subtitle = site.pollutionType != null
        ? mapPollutionTypeDisplay(context.l10n, site.pollutionType!)
        : mapStatusDisplay(
            context.l10n,
            mapStatusCodeFromUnknown(site.statusCode ?? site.statusLabel),
          );
    final TextStyle subtitleBase = AppTypography.cardSubtitle(
      textTheme,
    ).copyWith(fontSize: 13);
    final TextStyle subtitleEmphasis = subtitleBase.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Material(
      color: AppColors.transparent,
      child: Semantics(
        button: true,
        label: site.title,
        hint: subtitle,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? AppSpacing.sm : AppSpacing.radius14,
            ),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: SizedBox(
                    width: thumbSize,
                    height: thumbSize,
                    child: Image(
                      image: mapPinImageProviderForSite(site),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 12 : AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          children: mapSearchHighlightSpans(
                            text: site.title,
                            rawQuery: query,
                            baseStyle: baseTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            emphasisStyle: emphasis.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: mapSearchHighlightSpans(
                              text: subtitle,
                              rawQuery: query,
                              baseStyle: subtitleBase.copyWith(
                                color: AppColors.textMuted,
                              ),
                              emphasisStyle: subtitleEmphasis.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: compact ? 20 : 22,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
