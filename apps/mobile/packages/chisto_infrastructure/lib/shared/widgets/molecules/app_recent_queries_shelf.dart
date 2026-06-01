import 'package:chisto_infrastructure/shared/widgets/atoms/app_search_query_chip.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AppRecentQueriesShelfVariant { recent, suggestion }

/// Horizontal shelf of recent or suggested search queries.
class AppRecentQueriesShelf extends StatelessWidget {
  const AppRecentQueriesShelf({
    super.key,
    required this.title,
    required this.queries,
    required this.onQueryTap,
    this.onClear,
    this.clearLabel,
    this.variant = AppRecentQueriesShelfVariant.recent,
    this.highlightQuery,
    this.leadingIcon,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
    this.titleStyle,
    this.semanticLabelForQuery,
  });

  final String title;
  final List<String> queries;
  final ValueChanged<String> onQueryTap;
  final VoidCallback? onClear;
  final String? clearLabel;
  final AppRecentQueriesShelfVariant variant;
  final String? highlightQuery;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final String Function(String query)? semanticLabelForQuery;

  IconData? get _resolvedLeadingIcon {
    if (leadingIcon != null) {
      return leadingIcon;
    }
    return switch (variant) {
      AppRecentQueriesShelfVariant.recent => CupertinoIcons.time,
      AppRecentQueriesShelfVariant.suggestion => Icons.search_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return const SizedBox.shrink();
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle resolvedTitleStyle =
        titleStyle ??
        AppTypographySurfaces.homeSheetSectionLabel(textTheme).copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionHeader(
            title: title,
            padding: EdgeInsets.zero,
            titleStyle: resolvedTitleStyle,
            trailing: onClear != null && clearLabel != null
                ? AppSectionHeaderAction(
                    label: clearLabel!,
                    onPressed: onClear!,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xxs),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: queries.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) {
                final String query = queries[index];
                return AppSearchQueryChip(
                  label: query,
                  leadingIcon: _resolvedLeadingIcon,
                  highlightQuery: highlightQuery,
                  semanticLabel: semanticLabelForQuery?.call(query) ?? query,
                  onTap: () => onQueryTap(query),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
