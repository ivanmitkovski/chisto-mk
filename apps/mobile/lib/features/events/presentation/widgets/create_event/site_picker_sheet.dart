import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_sites_map.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class SitePickerSheet extends StatefulWidget {
  const SitePickerSheet({
    super.key,
    required this.allSites,
    required this.selectedSiteId,
    required this.onSelect,
    required this.onClose,
    this.initialShowMapTab = false,
    this.topBanners = const <Widget>[],
  });

  final List<EventSiteSummary> allSites;
  final String? selectedSiteId;
  final ValueChanged<EventSiteSummary> onSelect;
  final VoidCallback onClose;

  /// When true, opens with the map segment selected (e.g. from site-card mini-map).
  final bool initialShowMapTab;

  /// Shown below the list/map toggle (e.g. offline notice, load error + retry).
  final List<Widget> topBanners;

  @override
  State<SitePickerSheet> createState() => _SitePickerSheetState();
}

class _SitePickerSheetState extends State<SitePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late int _viewMode;

  static const int _modeList = 0;
  static const int _modeMap = 1;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialShowMapTab ? _modeMap : _modeList;
  }

  List<EventSiteSummary> get _filteredSites {
    if (_query.isEmpty) {
      return widget.allSites;
    }
    final String q = _query.toLowerCase();
    return widget.allSites
        .where((EventSiteSummary s) =>
            s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q))
        .toList();
  }

  List<EventSiteSummary> get _mappableFiltered {
    return _filteredSites
        .where(
          (EventSiteSummary s) => s.latitude != null && s.longitude != null,
        )
        .toList(growable: false);
  }

  static const EdgeInsets _listScrollPadding =
      EdgeInsets.only(bottom: AppSpacing.lg);

  static const double _segmentVerticalPadding = 10;

  String _subtitleFor(BuildContext context, EventSiteSummary site) {
    final String desc = site.description.trim();
    if (site.distanceKm >= 0) {
      return context.l10n.eventsSitePickerRowKmDesc(
        site.distanceKm.toStringAsFixed(1),
        desc,
      );
    }
    return desc.isEmpty ? site.title : desc;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<EventSiteSummary> filtered = _filteredSites;
    final List<EventSiteSummary> mappable = _mappableFiltered;

    return ReportSheetScaffold(
      title: context.l10n.eventsSitePickerTitle,
      subtitle: context.l10n.eventsSitePickerSubtitle,
      trailing: ReportCircleIconButton(
        icon: CupertinoIcons.xmark,
        semanticLabel: context.l10n.semanticsClose,
        onTap: widget.onClose,
      ),
      maxHeightFactor: 0.85,
      addBottomInset: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            label:
                '${context.l10n.createEventSitePickerTabList}, ${context.l10n.createEventSitePickerTabMap}',
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: AppColors.divider.withValues(alpha: 0.42),
                thumbColor: AppColors.panelBackground,
                padding: const EdgeInsets.all(3),
                groupValue: _viewMode,
                children: <int, Widget>{
                  _modeList: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: _segmentVerticalPadding,
                    ),
                    child: Text(
                      context.l10n.createEventSitePickerTabList,
                      style: AppTypography.eventsGroupedRowPrimary(
                        Theme.of(context).textTheme,
                      ).copyWith(letterSpacing: -0.25),
                    ),
                  ),
                  _modeMap: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: _segmentVerticalPadding,
                    ),
                    child: Text(
                      context.l10n.createEventSitePickerTabMap,
                      style: AppTypography.eventsGroupedRowPrimary(
                        Theme.of(context).textTheme,
                      ).copyWith(letterSpacing: -0.25),
                    ),
                  ),
                },
                onValueChanged: (int? value) {
                  if (value == null) {
                    return;
                  }
                  AppHaptics.tap(context);
                  setState(() => _viewMode = value);
                },
              ),
            ),
          ),
          if (widget.topBanners.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            ...widget.topBanners.expand(
              (Widget w) => <Widget>[w, const SizedBox(height: AppSpacing.sm)],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          CupertinoSearchTextField(
            controller: _searchController,
            placeholder: context.l10n.eventsSitePickerSearchPlaceholder,
            style: AppTypography.eventsSearchFieldText(
              Theme.of(context).textTheme,
            ).copyWith(letterSpacing: -0.2),
            placeholderStyle: AppTypography.eventsSearchFieldPlaceholder(
              Theme.of(context).textTheme,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.inputBorder.withValues(alpha: 0.65),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            itemColor: AppColors.textMuted,
            itemSize: 18,
            onChanged: (String value) => setState(() => _query = value),
            onSuffixTap: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_viewMode == _modeMap) ...<Widget>[
            if (mappable.isEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        CupertinoIcons.map,
                        size: 32,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.createEventSitePickerMapEmpty,
                        style: AppTypography.eventsBodyMuted(
                          Theme.of(context).textTheme,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double mapHeight = (constraints.maxHeight * 0.32)
                        .clamp(180.0, 260.0)
                        .toDouble();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          label: context
                              .l10n.createEventSitePickerMapSemanticLabel,
                          child: CreateEventSitesMap(
                            sites: filtered,
                            selectedSiteId: widget.selectedSiteId,
                            height: mapHeight,
                            onSiteTap: widget.onSelect,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.createEventSitePickerMapHint,
                          style: AppTypography.eventsListCardMeta(
                            Theme.of(context).textTheme,
                          ).copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (filtered.isEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    CupertinoIcons.search,
                                    size: 32,
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    context.l10n.eventsSitePickerNoMatch(_query),
                                    style: AppTypography.eventsBodyMuted(
                                      Theme.of(context).textTheme,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              padding: _listScrollPadding,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.xs),
                              itemBuilder:
                                  (BuildContext context, int index) {
                                final EventSiteSummary site =
                                    filtered[index];
                                final bool isActive =
                                    site.id == widget.selectedSiteId;
                                return _SitePickerLocationRow(
                                  title: site.title,
                                  subtitle: _subtitleFor(context, site),
                                  selected: isActive,
                                  onTap: () => widget.onSelect(site),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ] else if (filtered.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.search,
                      size: 32,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.eventsSitePickerNoMatch(_query),
                      style: AppTypography.eventsBodyMuted(
                        Theme.of(context).textTheme,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: _listScrollPadding,
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (BuildContext context, int index) {
                  final EventSiteSummary site = filtered[index];
                  final bool isActive = site.id == widget.selectedSiteId;
                  return _SitePickerLocationRow(
                    title: site.title,
                    subtitle: _subtitleFor(context, site),
                    selected: isActive,
                    onTap: () => widget.onSelect(site),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Grouped-list style row for the site picker (hairline border, soft selection tint).
class _SitePickerLocationRow extends StatelessWidget {
  const _SitePickerLocationRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      hint: subtitle,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.32)
                    : AppColors.divider.withValues(alpha: 0.75),
                width: selected ? 1 : 0.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: selected ? 0.03 : 0.04),
                  blurRadius: selected ? 6 : 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white
                        : AppColors.inputFill.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.divider.withValues(alpha: 0.55),
                    ),
                  ),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      CupertinoIcons.location_fill,
                      size: 22,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.eventsListCardTitle(textTheme).copyWith(
                          letterSpacing: -0.35,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eventsListCardMeta(textTheme).copyWith(
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.smooth,
                    switchOutCurve: AppMotion.smooth,
                    child: Icon(
                      selected
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      key: ValueKey<bool>(selected),
                      size: selected ? 24 : 22,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.divider.withValues(alpha: 0.95),
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
}
