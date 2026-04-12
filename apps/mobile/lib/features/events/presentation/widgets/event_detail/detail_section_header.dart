import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Consistent section header label used by all event-detail section widgets.
///
/// Renders the [title] in `sectionHeader` weight (18px w600 -0.2) with a
/// small bottom gap so callers don't need to add spacing inline.
class DetailSectionHeader extends StatelessWidget {
  const DetailSectionHeader(this.title, {super.key, this.bottomSpacing = AppSpacing.sm});

  final String title;

  /// Space between the header text and the content beneath it.
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: AppTypography.eventsSectionTitle(Theme.of(context).textTheme),
        ),
      ),
    );
  }
}
