import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

const double _kSurfacePillControlHeight = 48;
const double _kSurfacePillSelectedBorderAlpha = 0.5;
const double _kSurfacePillUnselectedBorderAlpha = 0.8;

/// One selectable filter pill in [AppFilterPillBar].
@immutable
class FilterPillItem<T> {
  const FilterPillItem({
    required this.value,
    required this.label,
    this.icon,
    this.semanticsLabel,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// When set, used as the full [Semantics.label]. Otherwise [label] only.
  final String? semanticsLabel;
}

/// Visual treatment for [AppFilterPillBar] (feed vs events historically differed).
enum AppFilterPillVariant {
  /// Material [FilterChip] + [AppColors] (home feed).
  feedChip,

  /// Themed surface “pill” row (events discovery).
  surfacePill,
}

/// Horizontal, scrollable filter pills shared by feed and events.
///
/// Single-select: [selected] must equal one of [items].value (or use a sentinel).
class AppFilterPillBar<T> extends StatelessWidget {
  const AppFilterPillBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.variant = AppFilterPillVariant.surfacePill,
    this.trailing,
    this.padding,
  });

  final List<FilterPillItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final AppFilterPillVariant variant;
  final Widget? trailing;

  /// Outer padding of the scroll strip (defaults: feed uses LTRB lg,0,lg,xs;
  /// surface pill uses zero — callers often wrap).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry resolvedPadding = padding ??
        (variant == AppFilterPillVariant.feedChip
            ? const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              )
            : const EdgeInsets.symmetric(horizontal: AppSpacing.lg));

    return Padding(
      padding: resolvedPadding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final FilterPillItem<T> item in items) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _Pill<T>(
                  item: item,
                  selected: selected,
                  variant: variant,
                  onSelected: onSelected,
                ),
              ),
            ],
            if (trailing case final Widget w) w,
          ],
        ),
      ),
    );
  }
}

class _Pill<T> extends StatelessWidget {
  const _Pill({
    required this.item,
    required this.selected,
    required this.variant,
    required this.onSelected,
  });

  final FilterPillItem<T> item;
  final T selected;
  final AppFilterPillVariant variant;
  final ValueChanged<T> onSelected;

  bool get _isActive => item.value == selected;

  @override
  Widget build(BuildContext context) {
    final String semantics =
        item.semanticsLabel ?? item.label;

    switch (variant) {
      case AppFilterPillVariant.feedChip:
        return Semantics(
          button: true,
          selected: _isActive,
          excludeSemantics: true,
          label: semantics,
          child: FilterChip(
            avatar: item.icon != null
                ? Icon(item.icon, size: 18)
                : null,
            label: Text(item.label),
            selected: _isActive,
            showCheckmark: false,
            onSelected: (_) {
              if (!_isActive) {
                AppHaptics.light(context);
                onSelected(item.value);
              }
            },
            selectedColor: AppColors.feedPillSelectedFill,
            labelStyle: AppTypography.chipLabel.copyWith(
              color: _isActive
                  ? AppColors.feedPillSelectedForeground
                  : AppColors.textSecondary,
              fontWeight: _isActive ? FontWeight.w600 : FontWeight.w500,
            ),
            side: BorderSide(
              color: _isActive
                  ? AppColors.feedPillSelectedBorder
                  : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
          ),
        );
      case AppFilterPillVariant.surfacePill:
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        return Semantics(
          button: true,
          selected: _isActive,
          label: semantics,
          child: SizedBox(
            height: _kSurfacePillControlHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!_isActive) {
                    AppHaptics.light(context);
                    onSelected(item.value);
                  }
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _isActive
                        ? colorScheme.primaryContainer
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: _isActive
                          ? colorScheme.primary
                              .withValues(alpha: _kSurfacePillSelectedBorderAlpha)
                          : colorScheme.outlineVariant.withValues(
                              alpha: _kSurfacePillUnselectedBorderAlpha,
                            ),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (item.icon != null) ...<Widget>[
                        Icon(
                          item.icon,
                          size: 18,
                          color: _isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight:
                                  _isActive ? FontWeight.w600 : FontWeight.w500,
                              color: _isActive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
