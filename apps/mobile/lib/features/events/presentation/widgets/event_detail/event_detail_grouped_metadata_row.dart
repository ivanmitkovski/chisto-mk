import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_layout.dart';

/// Layout tokens shared by [EventDetailGroupedMetadataRow] and
/// [EventDetailGroupedPanel] divider alignment.
abstract final class EventDetailGroupedMetadataRowLayout {
  static const double leadingBoxSize = 32;
  static const double leadingIconSize = 20;
  static const double leadingAfterGap = AppSpacing.sm;

  /// Inset from the **card’s** physical left edge to the start of the primary
  /// text column (panel wraps each child with [AppSpacing.md] horizontal padding).
  static double get dividerInsetFromCardEdge =>
      AppSpacing.md + leadingBoxSize + leadingAfterGap;

  /// Leading offset for nested dividers inside a row that already sits under
  /// the panel’s horizontal padding.
  static double get innerDividerLeadingPadding =>
      leadingBoxSize + leadingAfterGap;
}

/// Fixed-size leading icon slot for grouped metadata rows (location, schedule, etc.).
class EventDetailGroupedMetadataRowLeading extends StatelessWidget {
  const EventDetailGroupedMetadataRowLeading({
    super.key,
    required this.icon,
    this.iconColor = AppColors.textSecondary,
    this.iconSize = EventDetailGroupedMetadataRowLayout.leadingIconSize,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: EventDetailGroupedMetadataRowLayout.leadingBoxSize,
      height: EventDetailGroupedMetadataRowLayout.leadingBoxSize,
      child: Center(
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}

/// One row inside [EventDetailGroupedPanel]: leading slot, primary block, optional trailing.
class EventDetailGroupedMetadataRow extends StatelessWidget {
  const EventDetailGroupedMetadataRow({
    super.key,
    required this.leading,
    required this.center,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget leading;
  final Widget center;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: kEventDetailGroupedRowMinHeight,
      ),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: <Widget>[
          leading,
          const SizedBox(
            width: EventDetailGroupedMetadataRowLayout.leadingAfterGap,
          ),
          Expanded(child: center),
          ?trailing,
        ],
      ),
    );
  }
}
