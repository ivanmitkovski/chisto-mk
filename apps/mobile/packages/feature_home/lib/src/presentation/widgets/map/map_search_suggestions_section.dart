import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_search_query_chip.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/utils/map_search_highlight.dart';
import 'package:flutter/material.dart';

/// Remote suggestions and optional geo intent for map search.
class MapSearchSuggestionsSection extends StatelessWidget {
  const MapSearchSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.query,
    required this.onSuggestionTap,
    this.geoIntent,
    this.onGeoIntentTap,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  final List<String> suggestions;
  final String query;
  final ValueChanged<String> onSuggestionTap;
  final SiteMapSearchGeoIntent? geoIntent;
  final ValueChanged<SiteMapSearchGeoIntent>? onGeoIntentTap;
  final EdgeInsetsGeometry padding;

  bool get _hasSuggestions => suggestions.isNotEmpty;
  bool get _hasGeoIntent => geoIntent != null && onGeoIntentTap != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasSuggestions && !_hasGeoIntent) {
      return const SizedBox.shrink();
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle sectionLabel = AppTypographySurfaces.homeSheetSectionLabel(
      textTheme,
    );

    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.inputFill.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.65)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_hasSuggestions) ...<Widget>[
                AppSectionHeader(
                  title: context.l10n.mapSearchSuggestionsLabel,
                  padding: EdgeInsets.zero,
                  titleStyle: sectionLabel.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (BuildContext context, int index) {
                      final String suggestion = suggestions[index];
                      return AppSearchQueryChip(
                        label: suggestion,
                        highlightQuery: query,
                        leadingIcon: Icons.search_rounded,
                        semanticLabel: context.l10n
                            .mapSearchSuggestionChipSemantic(suggestion),
                        onTap: () => onSuggestionTap(suggestion),
                      );
                    },
                  ),
                ),
              ],
              if (_hasSuggestions && _hasGeoIntent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(
                    height: 1,
                    color: AppColors.divider.withValues(alpha: 0.55),
                  ),
                ),
              if (_hasGeoIntent)
                _MapSearchGeoIntentTile(
                  intent: geoIntent!,
                  query: query,
                  onTap: () => onGeoIntentTap!(geoIntent!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSearchGeoIntentTile extends StatelessWidget {
  const _MapSearchGeoIntentTile({
    required this.intent,
    required this.query,
    required this.onTap,
  });

  final SiteMapSearchGeoIntent intent;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle titleBase = AppTypography.cardTitle(
      textTheme,
    ).copyWith(fontSize: 15, color: AppColors.textPrimary);
    final TextStyle titleEmphasis = titleBase.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      button: true,
      label: context.l10n.mapSearchGeoIntentSemantic(intent.label),
      hint: context.l10n.mapSearchGeoIntentSubtitle,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.feedPillSelectedFill,
                    borderRadius: BorderRadius.circular(AppSpacing.radius10),
                    border: Border.all(color: AppColors.feedPillSelectedBorder),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    size: 18,
                    color: AppColors.feedPillSelectedForeground,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          children: mapSearchHighlightSpans(
                            text: intent.label,
                            rawQuery: query,
                            baseStyle: titleBase,
                            emphasisStyle: titleEmphasis,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.l10n.mapSearchGeoIntentSubtitle,
                        style: AppTypographySurfaces.homeMutedCaption(
                          textTheme,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
