import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

class HeroEventCard extends StatelessWidget {
  const HeroEventCard({super.key, required this.event, required this.onTap});

  final EcoEvent event;
  final VoidCallback onTap;

  String get _countdownLabel {
    final Duration diff = event.startDateTime.difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    if (diff.inDays > 0) return 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'Starts in ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.emphasized,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Hero(
                tag: 'event-thumb-${event.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Image.asset(
                      event.siteImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.transparent,
                        AppColors.black.withValues(alpha: 0.7),
                      ],
                      stops: const <double>[0.3, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.radiusSm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        _countdownLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.radiusSm),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        const Icon(CupertinoIcons.location_solid, size: 12, color: AppColors.textOnDarkMuted),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            event.siteName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnDarkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.radiusSm),
                        Text(
                          event.formattedTimeRange,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textOnDarkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.radius10,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radius10),
                  ),
                  child: Text(
                    'Up next',
                    style: AppTypography.badgeLabel.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
