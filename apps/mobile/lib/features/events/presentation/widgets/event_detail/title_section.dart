import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';

class TitleSection extends StatelessWidget {
  const TitleSection({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius10, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: event.status.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Text(
            event.status.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: event.status.color,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          event.title,
          style: textTheme.titleLarge?.copyWith(
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
