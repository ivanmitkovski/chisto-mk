import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';

/// Single card grouping for list-like metadata rows (location, schedule, category, details).
///
/// Uses iOS-style **inset dividers**: each separator is offset from the leading
/// edge by [_kDividerInset] so it aligns just after the row's leading icon,
/// matching Apple's UITableView grouped style exactly.
class EventDetailGroupedPanel extends StatelessWidget {
  const EventDetailGroupedPanel({super.key, required this.children});

  final List<Widget> children;

  // icon_md (20) + panel horizontal padding (md = 16) + gap (sm = 12) = 48
  static const double _kDividerInset =
      AppSpacing.md + AppSpacing.iconMd + AppSpacing.sm;

  /// Inset for dividers **inside** a padded row group (aligns with primary text).
  static const double innerDividerLeadingPadding =
      AppSpacing.iconMd + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: children[i],
        ),
      );
      if (i < children.length - 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(left: _kDividerInset),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.divider.withValues(alpha: 0.7),
            ),
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: EventDetailSurfaceDecoration.elevatedCard(),
      child: ClipRRect(
        borderRadius: EventDetailSurfaceDecoration.cardBorderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      ),
    );
  }
}
