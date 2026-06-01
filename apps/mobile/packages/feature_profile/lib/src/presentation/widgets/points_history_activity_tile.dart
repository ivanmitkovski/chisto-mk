import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/points_history_page.dart';
import 'package:flutter/material.dart';

class PointsHistoryActivityTile extends StatelessWidget {
  const PointsHistoryActivityTile({
    super.key,
    required this.entry,
    required this.reasonTitle,
    required this.reasonIcon,
    required this.deltaLabel,
    required this.timeLine,
    required this.semanticLabel,
  });

  final PointsHistoryEntry entry;
  final String reasonTitle;
  final IconData reasonIcon;
  final String deltaLabel;
  final String timeLine;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color deltaColor = entry.delta >= 0
        ? AppColors.primaryDark
        : AppColors.textSecondary;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radius18),
          boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radius14),
                ),
                child: Icon(reasonIcon, color: AppColors.primaryDark, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      reasonTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypographySurfaces.profilePointsActivityTitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLine,
                      style:
                          AppTypographySurfaces.profilePointsActivitySubtitle(
                            Theme.of(context).textTheme,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                deltaLabel,
                style: AppTypographySurfaces.profilePointsDelta(
                  Theme.of(context).textTheme,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
