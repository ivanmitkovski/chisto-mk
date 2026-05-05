import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/utils/profile_level_tier.dart';

double _levelProgressBarWidthFactor(double progress) {
  final double p = progress.clamp(0.0, 1.0);
  if (p <= 0) return 0.0;
  if (p >= 1.0) return 1.0;
  return p < 0.04 ? 0.04 : p;
}

/// Level tier, XP bar, and tap target to open points history (profile home).
class ProfileLevelAndPointsCard extends StatelessWidget {
  const ProfileLevelAndPointsCard({
    super.key,
    required this.user,
    required this.onOpenPointsHistory,
  });

  final ProfileUser user;
  final VoidCallback onOpenPointsHistory;

  @override
  Widget build(BuildContext context) {
    final double progress = user.levelProgress.clamp(0.0, 1.0);
    final double widthFactor = _levelProgressBarWidthFactor(progress);
    final int segmentTotal = user.pointsInLevel + user.pointsToNextLevel;

    return Semantics(
      button: true,
      label: context.l10n.profileLevelCardSemantic,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpenPointsHistory,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: AppSpacing.xxl,
                        height: AppSpacing.xxl,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radius14,
                          ),
                        ),
                        child: Icon(
                          profileTierIcon(user.levelTierKey),
                          color: AppColors.primaryDark,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              profileTierTitle(context, user),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.profilePtsToNextLevel(
                                user.pointsToNextLevel,
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusCircle,
                    ),
                    child: SizedBox(
                      height: AppSpacing.radius18,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          const ColoredBox(color: AppColors.inputFill),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: widthFactor,
                              heightFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusCircle,
                                  ),
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      AppColors.primaryDark,
                                      AppColors.primary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Dense dual-caption row: clamp text scale so the bar layout
                  // stays stable under large accessibility fonts.
                  if (segmentTotal > 0)
                    MediaQuery.withClampedTextScaling(
                      minScaleFactor: 1,
                      maxScaleFactor: 1.35,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              context.l10n.profileLevelXpSegment(
                                user.pointsInLevel,
                                segmentTotal,
                              ),
                              textAlign: TextAlign.start,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              context.l10n.profileLifetimeXpOnBar(
                                user.totalPointsEarned,
                              ),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    MediaQuery.withClampedTextScaling(
                      minScaleFactor: 1,
                      maxScaleFactor: 1.35,
                      child: Text(
                        context.l10n.profileLifetimeXpOnBar(
                          user.totalPointsEarned,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
