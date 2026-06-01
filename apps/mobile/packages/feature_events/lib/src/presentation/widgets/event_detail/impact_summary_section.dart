import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/event_feedback_local_cache.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      decoration: EventDetailSurfaceDecoration.detailModule(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                context.l10n.eventsImpactSummaryTitle,
                style: AppTypography.eventsPanelTitle(textTheme),
              ),
              const Spacer(),
              CupertinoButton(
                onPressed: onEdit,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                minimumSize: const Size(44, 44),
                child: Text(
                  data == null
                      ? context.l10n.eventsImpactSummaryAdd
                      : context.l10n.eventsImpactSummaryEdit,
                ),
              ),
            ],
          ),
          if (data == null) ...<Widget>[
            Text(
              context.l10n.eventsImpactSummaryEmptyHint,
              style: AppTypography.eventsBodyMuted(textTheme),
            ),
          ] else ...<Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                ImpactBadge(
                  label: context.l10n.eventsImpactBadgeRating(data.rating),
                ),
                ImpactBadge(
                  label: context.l10n.eventsImpactBadgeBags(data.bagsCollected),
                ),
                ImpactBadge(
                  label: context.l10n.eventsImpactBadgeHours(
                    data.volunteerHours.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.eventsImpactEstimatedLine(
                data.estimatedKg.toStringAsFixed(1),
                data.estimatedCo2SavedKg.toStringAsFixed(1),
              ),
              style: AppTypography.eventsCaptionStrong(
                textTheme,
                color: AppColors.primaryDark,
              ),
            ),
            if (data.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.eventsGridPropertyValue(textTheme),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.radius10,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.eventsCaptionStrong(
          Theme.of(context).textTheme,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
