import 'package:chisto_infrastructure/core/theme/app_colors.dart';
import 'package:chisto_infrastructure/core/theme/app_shadows.dart';
import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:chisto_infrastructure/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class WeeklyRankingsEmpty extends StatelessWidget {
  const WeeklyRankingsEmpty({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 30,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.emptyStateTitle(
                  textTheme,
                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.authSubtitle(textTheme).copyWith(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.35,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
