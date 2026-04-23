import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_painters.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Post check-in success state with optional points line and primary “Done”.
class AttendeeQrScannerSuccessScaffold extends StatelessWidget {
  const AttendeeQrScannerSuccessScaffold({
    super.key,
    required this.eventTitle,
    required this.checkedInTime,
    required this.pointsAwarded,
    required this.bottomSafe,
    required this.onDone,
  });

  final String eventTitle;
  final String? checkedInTime;
  final int pointsAwarded;
  final double bottomSafe;
  final VoidCallback onDone;

  static const double _successMarkSize = 88;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget mark = Container(
      width: _successMarkSize,
      height: _successMarkSize,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: reduceMotion
          ? CustomPaint(
              painter: AttendeeQrCheckmarkPainter(
                progress: 1,
                color: AppColors.primaryDark,
                strokeWidth: 4,
              ),
              size: const Size(_successMarkSize, _successMarkSize),
            )
          : TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: AppMotion.emphasizedDuration,
              curve: AppMotion.emphasized,
              builder: (BuildContext context, double progress, Widget? child) {
                return CustomPaint(
                  painter: AttendeeQrCheckmarkPainter(
                    progress: progress,
                    color: AppColors.primaryDark,
                    strokeWidth: 4,
                  ),
                  size: const Size(_successMarkSize, _successMarkSize),
                );
              },
            ),
    );

    final Widget scaledMark = reduceMotion
        ? mark
        : TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.standard,
            curve: AppMotion.emphasized,
            builder: (BuildContext context, double scale, Widget? child) {
              return Transform.scale(
                scale: 0.92 + 0.08 * scale,
                child: Opacity(opacity: scale, child: child),
              );
            },
            child: mark,
          );

    final Widget textBlock = Column(
      children: <Widget>[
        Text(
          l10n.qrScannerCheckedInTitle,
          style: AppTypography.eventsDetailHeadline(textTheme).copyWith(
            fontSize: textTheme.headlineSmall?.fontSize,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.qrScannerWelcomeTo(eventTitle),
          style: AppTypography.eventsDetailAuxRowTitle(textTheme).copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        if (checkedInTime != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.qrScannerCheckedInAt(checkedInTime!),
            style: AppTypography.eventsListCardMeta(textTheme).copyWith(height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
        if (pointsAwarded > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.eventsCheckInPointsEarned(pointsAwarded),
            style: AppTypography.eventsCalendarMonthTitle(textTheme).copyWith(
              color: AppColors.primaryDark,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    final Widget animatedText = reduceMotion
        ? textBlock
        : TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.standard,
            curve: Interval(0.12, 1, curve: AppMotion.emphasized),
            builder: (BuildContext context, double t, Widget? child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - t)),
                  child: child,
                ),
              );
            },
            child: textBlock,
          );

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.appBackground,
        leading: const AppBackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl + bottomSafe,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              scaledMark,
              SizedBox(height: AppSpacing.xl + AppSpacing.xs),
              animatedText,
              const Spacer(),
              Semantics(
                button: true,
                label: l10n.qrScannerDone,
                child: PrimaryButton(
                  label: l10n.qrScannerDone,
                  enabled: true,
                  onPressed: onDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
