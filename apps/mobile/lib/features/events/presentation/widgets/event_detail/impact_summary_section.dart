import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';

class ImpactSummarySection extends StatelessWidget {
  const ImpactSummarySection({
    super.key,
    required this.snapshot,
    required this.onEdit,
  });

  final EventFeedbackSnapshot? snapshot;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final EventFeedbackSnapshot? data = snapshot;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Impact summary',
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              CupertinoButton(
                onPressed: onEdit,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: Size.zero,
                child: Text(data == null ? 'Add' : 'Edit'),
              ),
            ],
          ),
          if (data == null) ...<Widget>[
            Text(
              'Capture cleanup outcomes, effort, and lessons learned.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ] else ...<Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                ImpactBadge(label: '${data.rating}★ rating'),
                ImpactBadge(label: '${data.bagsCollected} bags'),
                ImpactBadge(label: '${data.volunteerHours.toStringAsFixed(1)}h'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${data.estimatedKg.toStringAsFixed(1)} kg removed · '
              '${data.estimatedCo2SavedKg.toStringAsFixed(1)} kg CO2e avoided',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (data.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class ImpactBadge extends StatelessWidget {
  const ImpactBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
