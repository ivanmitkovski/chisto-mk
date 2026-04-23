import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Full-screen “waiting for organizer confirmation” state after a check-in request.
class AttendeeQrScannerPendingPanel extends StatelessWidget {
  const AttendeeQrScannerPendingPanel({
    super.key,
    required this.eventTitle,
    required this.bottomSafe,
    required this.onCancel,
  });

  final String eventTitle;
  final double bottomSafe;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget progressOrb = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
      ),
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
      ),
    );

    final Widget animatedOrb = reduceMotion
        ? progressOrb
        : TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.standard,
            builder: (BuildContext ctx, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * value,
                  child: child,
                ),
              );
            },
            child: progressOrb,
          );

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Semantics(
            label:
                '${l10n.eventsVolunteerPendingTitle}. ${l10n.eventsVolunteerPendingSubtitle}',
            liveRegion: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                animatedOrb,
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.eventsVolunteerPendingTitle,
                  style: AppTypography.eventsScreenTitle(textTheme)
                      .copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.eventsVolunteerPendingSubtitle,
                  style: AppTypography.eventsBodyMediumSecondary(textTheme).copyWith(
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  eventTitle,
                  style: AppTypography.eventsListCardMeta(textTheme),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: bottomSafe + AppSpacing.md),
                  child: TextButton(
                    onPressed: onCancel,
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                      style: AppTypography.eventsBodyMediumSecondary(textTheme),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
