import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Large event title below the hero. Date and time live in [DateTimeSection] so
/// they are not repeated (Calendar-style: title + structured rows).
///
/// Horizontal [AppSpacing.md] inset matches the primary text column inside
/// [EventDetailSurfaceDecoration] modules (thank-you card, impact receipt row,
/// fact cards) so the headline aligns with body copy on the same screen.
class TitleSection extends StatelessWidget {
  const TitleSection({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        event.title,
        style: AppTypography.eventsDetailHeadline(textTheme),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      ),
    );
  }
}
