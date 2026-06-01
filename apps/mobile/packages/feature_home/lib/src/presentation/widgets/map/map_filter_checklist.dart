import 'package:design_system/design_system.dart';
import 'package:design_system/src/theme/app_typography_surfaces.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Full-width grouped table for map filter rows (iOS Settings inset style).
class MapFilterInsetGroup extends StatelessWidget {
  const MapFilterInsetGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputFill.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Multi-select filter row with optional status dot and trailing checkmark.
class MapFilterCheckRow extends StatelessWidget {
  const MapFilterCheckRow({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingDotColor,
    this.semanticLabel,
    this.semanticHint,
    this.showDivider = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? leadingDotColor;
  final String? semanticLabel;
  final String? semanticHint;
  final bool showDivider;

  static const double _rowHorizontalPadding = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          selected: isSelected,
          label: semanticLabel ?? label,
          hint: semanticHint,
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _rowHorizontalPadding,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (leadingDotColor != null) ...<Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: leadingDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.bodyMedium!.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Icon(
                          isSelected
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: leadingDotColor != null
                ? _rowHorizontalPadding + 8 + AppSpacing.sm
                : _rowHorizontalPadding,
            endIndent: _rowHorizontalPadding,
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

/// Single toggle row for boolean filter options.
class MapFilterSwitchRow extends StatelessWidget {
  const MapFilterSwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.showDivider = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          label: semanticLabel ?? title,
          hint: subtitle,
          toggled: value,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.textTheme.bodyMedium!.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        subtitle,
                        style: AppTypographySurfaces.homeMutedCaption(
                          textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

/// Fixed-height shelf for active exclusion chips so toggling filters does not
/// shift the sheet layout.
class MapFilterSummaryChipShelf extends StatelessWidget {
  const MapFilterSummaryChipShelf({super.key, required this.chips});

  final List<Widget> chips;

  static const double shelfHeight = 44;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: shelfHeight,
      child: chips.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) => chips[index],
            ),
    );
  }
}
