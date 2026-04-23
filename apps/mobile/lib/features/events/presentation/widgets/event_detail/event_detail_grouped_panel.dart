import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_grouped_metadata_row.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';

/// Single card grouping for list-like metadata rows (location, schedule, category, details).
///
/// Uses iOS-style **inset dividers**: each separator is offset from the leading
/// edge so it aligns with the primary text column of [EventDetailGroupedMetadataRow].
class EventDetailGroupedPanel extends StatelessWidget {
  const EventDetailGroupedPanel({super.key, required this.children});

  final List<Widget> children;

  static double get _kDividerInset =>
      EventDetailGroupedMetadataRowLayout.dividerInsetFromCardEdge;

  /// Inset for dividers **inside** a padded row group (aligns with primary text).
  static double get innerDividerLeadingPadding =>
      EventDetailGroupedMetadataRowLayout.innerDividerLeadingPadding;

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
            padding: EdgeInsets.only(left: _kDividerInset),
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
      decoration: EventDetailSurfaceDecoration.groupedListShell(),
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
