import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/data/map_search_recents_store.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_camera_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_derived_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_search_controller.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/utils/map_search_highlight.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_site_pin_image.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_pollution_type_ui.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_empty_state.dart';
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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final MapSearchController _search = MapSearchController(
    remoteSearch: (SiteMapSearchRequest req) =>
        ref.read(sitesRepositoryProvider).searchSitesForMap(req),
    initialLocalPool: ref.read(mapSearchLocalPoolProvider),
    filterContext: _filterContextFrom(ref.read(mapFilterNotifierProvider)),
    cameraLat: ref.read(mapCameraNotifierProvider).centerLat,
    cameraLng: ref.read(mapCameraNotifierProvider).centerLng,
  );
  List<String> _recents = const <String>[];

  Future<void> _refreshRecents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _recents = MapSearchRecentsStore.readSync(prefs);
    if (mounted) {
      setState(() {});
    }
  }

  SiteMapSearchFilterContext _filterContextFrom(MapFilterState f) {
    return SiteMapSearchFilterContext(
      statuses:
          f.activeStatuses.map(mapStatusCodeFromUnknown).toList(),
      pollutionTypes: f.activePollutionTypes
          .map(reportPollutionTypeCodeFromUnknown)
          .toList(),
      includeArchived: f.includeArchived,
    );
  }

  void _onQueryChanged() => _search.updateQuery(_controller.text);

  Future<void> _onSiteSelected(PollutionSite site) async {
    final String q = _controller.text.trim();
    if (q.length >= 2) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await MapSearchRecentsStore.add(prefs, q);
      await _refreshRecents();
    }
    widget.onResultTap(site);
  }

  @override
  void initState() {
    super.initState();
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
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<PollutionSite> pool = ref.watch(mapSearchLocalPoolProvider);
    final MapCameraState camera = ref.watch(mapCameraNotifierProvider);
    final MapFilterState filter = ref.watch(mapFilterNotifierProvider);
    _search.setLocalPool(pool);
    _search.setCamera(camera.centerLat, camera.centerLng);
    _search.setFilterContext(_filterContextFrom(filter));

    return AnimatedBuilder(
      animation: _search,
      builder: (BuildContext context, _) {
        final MapSearchState state = _search.state;
        final bool isCompact = MediaQuery.of(context).size.width < 400;
        final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
        final bool hasRemoteLoading =
            state.remotePhase == MapSearchRemotePhase.loading;
        final bool hasRemoteError =
            state.remotePhase == MapSearchRemotePhase.error;
        final bool showResults = state.localResults.isNotEmpty ||
            state.remoteOnlyResults.isNotEmpty;
        final bool showEmptyQuery = !state.hasQuery;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? AppSpacing.sm : AppSpacing.lg,
                  AppSpacing.sm,
                  isCompact ? AppSpacing.sm : AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        textField: true,
                        label: context.l10n.searchModalPlaceholder,
                        hint: context.l10n.mapSearchFieldSemanticHint,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.search,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.inputFill,
                            hintText: context.l10n.searchModalPlaceholder,
                            hintStyle:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            isDense: true,
                            // Same stroke width for all states so the pill outline
                            // does not shift when focus or suffix changes.
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                              borderSide: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.9),
                                width: 1,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: AppSpacing.iconMd,
                              color: AppColors.textSecondary,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 40,
                            ),
                            suffixIcon: _controller.text.isEmpty
                                ? null
                                : IconButton(
                                    style: IconButton.styleFrom(
                                      foregroundColor: AppColors.textMuted,
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.all(AppSpacing.xs),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed: () {
                                      _controller.clear();
                                      _search.clearQuery();
                                    },
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      size: AppSpacing.iconSm,
                                    ),
                                  ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state.hasQuery && state.totalMatchCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            child: Text(
                              context.l10n.mapSearchResultsBadge(
                                state.totalMatchCount,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        textStyle:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      onPressed: widget.onDismiss,
                      child: Text(context.l10n.searchModalCancel),
                    ),
                  ],
                ),
              ),
              if (hasRemoteLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (hasRemoteError)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    AppSpacing.xs,
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          context.l10n.mapSearchRemoteError,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.accentDanger,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: _search.retryRemote,
                        child: Text(context.l10n.mapSearchRemoteRetry),
                      ),
                    ],
                  ),
                ),
              if (state.hasQuery &&
                  state.geoIntent != null &&
                  widget.onGeoIntentSelected != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    AppSpacing.xs,
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.place_outlined, size: 18),
                      label: Text(
                        state.geoIntent!.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      onPressed: () {
                        AppHaptics.light(context);
                        widget.onGeoIntentSelected!(state.geoIntent!);
                      },
                    ),
                  ),
                ),
              if (state.hasQuery && state.suggestions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    0,
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        Text(
                          context.l10n.mapSearchSuggestionsLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        ...state.suggestions.map(
                          (String s) => ActionChip(
                            label: Text(
                              s,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              _controller.text = s;
                              _search.updateQuery(s);
                              AppHaptics.light(context);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showEmptyQuery && _recents.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    0,
                    isCompact ? AppSpacing.sm : AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            context.l10n.mapSearchRecentsLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xxs,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () async {
                              AppHaptics.light(context);
                              final SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await MapSearchRecentsStore.clear(prefs);
                              await _refreshRecents();
                            },
                            child: Text(
                              context.l10n.mapSearchClearRecentsButton,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: _recents
                              .map(
                                (String r) => ActionChip(
                                  label: Text(
                                    r,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () {
                                    _controller.text = r;
                                    _search.updateQuery(r);
                                    AppHaptics.light(context);
                                    setState(() {});
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!showResults)
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(bottom: keyboardBottom + AppSpacing.md),
                    child: showEmptyQuery
                        ? AppEmptyState(
                            icon: Icons.map_rounded,
                            title: context.l10n.mapSearchEmptyTitle,
                            subtitle: context.l10n.mapSearchEmptySubtitle,
                          )
                        : state.isDebouncingLocal || hasRemoteLoading
                            ? Center(
                                child: Text(
                                  context.l10n.mapSearchRemoteLoading,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : AppEmptyState(
                                icon: Icons.search_off_rounded,
                                title: context.l10n.mapSearchNoResultsTitle,
                                subtitle:
                                    context.l10n.mapSearchNoResultsSubtitle,
                              ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: keyboardBottom),
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: <Widget>[
                        if (state.localResults.isNotEmpty) ...<Widget>[
                          _SectionHeader(
                            title: context.l10n.mapSearchSectionOnMap,
                            compact: isCompact,
                          ),
                          ..._tilesFor(
                            sites: state.localResults,
                            query: state.query,
                            compact: isCompact,
                          ),
                        ],
                        if (state.remoteOnlyResults.isNotEmpty) ...<Widget>[
                          _SectionHeader(
                            title: context.l10n.mapSearchSectionEverywhere,
                            compact: isCompact,
                          ),
                          ..._tilesFor(
                            sites: state.remoteOnlyResults,
                            query: state.query,
                            compact: isCompact,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _tilesFor({
    required List<PollutionSite> sites,
    required String query,
    required bool compact,
  }) {
    final List<Widget> out = <Widget>[];
    for (int i = 0; i < sites.length; i++) {
      if (i > 0) {
        out.add(
          Divider(
            height: 1,
            color: AppColors.divider.withValues(alpha: 0.35),
          ),
        );
      }
      final PollutionSite site = sites[i];
      out.add(
        _SearchResultTile(
          site: site,
          query: query,
          onTap: () => _onSiteSelected(site),
          compact: compact,
        ),
      );
    }
    return out;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.compact,
  });

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs,
        compact ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
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
    final double thumbSize = compact ? 48 : 52;
    final TextTheme tt = Theme.of(context).textTheme;
    final TextStyle baseTitle = tt.bodyLarge ??
        tt.bodyMedium ??
        AppTypography.cardTitle.copyWith(fontSize: 16);
    final TextStyle emphasis = baseTitle.copyWith(fontWeight: FontWeight.w700);
    final String subtitle = site.pollutionType != null
        ? mapPollutionTypeDisplay(context.l10n, site.pollutionType!)
        : mapStatusDisplay(
            context.l10n,
            mapStatusCodeFromUnknown(site.statusCode ?? site.statusLabel),
          );
    final TextStyle subtitleBase = Theme.of(context).textTheme.bodySmall ??
        AppTypography.cardSubtitle.copyWith(fontSize: 13);
    final TextStyle subtitleEmphasis =
        subtitleBase.copyWith(fontWeight: FontWeight.w700);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.light(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: compact ? 12 : 14,
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
                          baseStyle: baseTitle.copyWith(color: AppColors.textPrimary),
                          emphasisStyle:
                              emphasis.copyWith(color: AppColors.textPrimary),
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
                            baseStyle:
                                subtitleBase.copyWith(color: AppColors.textMuted),
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
    );
  }
}
