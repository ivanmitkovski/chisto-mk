import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Consistent section header label used by all event-detail section widgets.
///
/// Renders the [title] in `sectionHeader` weight (18px w600 -0.2) with a
/// small bottom gap so callers don't need to add spacing inline.
class DetailSectionHeader extends StatelessWidget {
  const DetailSectionHeader(
    this.title, {
    super.key,
    this.bottomSpacing = AppSpacing.sm,
    this.trailing,
  });

  final String title;

  /// Space between the header text and the content beneath it.
  final double bottomSpacing;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = AppTypography.eventsSectionTitle(
      Theme.of(context).textTheme,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Semantics(
        header: true,
        child: trailing == null
            ? Text(title, style: titleStyle)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: Text(title, style: titleStyle)),
                  trailing!,
                ],
              ),
      ),
    );
  }
}
