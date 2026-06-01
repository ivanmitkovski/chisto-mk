import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_labels.dart';
import 'package:flutter/material.dart';

/// Circular tone-tinted icon node for a timeline entry.
class SiteHistoryTimelineNode extends StatelessWidget {
  const SiteHistoryTimelineNode({super.key, required this.kind});

  final SiteHistoryEntryKind kind;

  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    final Color accent = siteHistoryEntryAccentColor(kind);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: siteHistoryEntryAccentBackground(kind),
        shape: BoxShape.circle,
        border: Border.all(color: siteHistoryEntryAccentBorder(kind), width: 1),
      ),
      child: Icon(siteHistoryEntryIcon(kind), size: 18, color: accent),
    );
  }
}

/// Left gutter rail: continuous connector line with optional centered node.
class SiteHistoryTimelineRail extends StatelessWidget {
  const SiteHistoryTimelineRail({
    super.key,
    required this.showLineAbove,
    required this.showLineBelow,
    this.node,
  });

  static const double gutterWidth = 40;

  final bool showLineAbove;
  final bool showLineBelow;
  final Widget? node;

  @override
  Widget build(BuildContext context) {
    final Color lineColor = AppColors.divider.withValues(alpha: 0.85);
    return SizedBox(
      width: gutterWidth,
      child: Column(
        children: <Widget>[
          Expanded(
            child: showLineAbove
                ? Center(child: Container(width: 1.5, color: lineColor))
                : const SizedBox.shrink(),
          ),
          node ??
              const SizedBox(
                width: SiteHistoryTimelineNode.size,
                height: SiteHistoryTimelineNode.size,
              ),
          Expanded(
            child: showLineBelow
                ? Center(child: Container(width: 1.5, color: lineColor))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
