import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:intl/intl.dart';

/// Event title and schedule subtitle below the hero (status pill lives on [HeroImageBar]).
class TitleSection extends StatelessWidget {
  const TitleSection({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final String datePart = DateFormat.yMMMEd(
      Localizations.localeOf(context).toString(),
    ).format(event.date);
    final String scheduleSubtitle = '$datePart · ${event.formattedTimeRange}';

    final TextTheme textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            event.title,
            style: AppTypography.eventsDetailHeadline(textTheme),
          ),
          SizedBox(height: AppSpacing.xs),
          Semantics(
            label: scheduleSubtitle,
            child: Text(
              scheduleSubtitle,
              style: AppTypography.eventsDetailScheduleLine(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}
