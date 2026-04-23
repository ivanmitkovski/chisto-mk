import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

Widget attendeeQrScannerLoadingLayer(BuildContext context) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final AppLocalizations l10n = context.l10n;
  return ColoredBox(
    color: AppColors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CupertinoActivityIndicator(color: AppColors.white),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              l10n.qrScannerCameraStarting,
              style: AppTypography.eventsChatMessageBody(
                textTheme,
                color: AppColors.textOnDarkMuted,
              ).copyWith(height: 1.35),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget attendeeQrScannerGlassChip(
  BuildContext context, {
  required IconData icon,
  required String text,
}) {
  final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
  final TextTheme textTheme = Theme.of(context).textTheme;
  final Widget inner = DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.glassDark,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.eventsChatMessageBody(
                textTheme,
                color: AppColors.textOnDark,
              ).copyWith(height: 1.35, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ),
  );
  if (reduceMotion) {
    return inner;
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: inner,
    ),
  );
}

Widget attendeeQrScannerGlassBottomPanel(
  BuildContext context, {
  required Widget child,
}) {
  final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
  final Widget inner = DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.glassDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: child,
    ),
  );
  if (reduceMotion) {
    return inner;
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: inner,
    ),
  );
}

Widget attendeeQrScannerProcessingHud(BuildContext context) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final AppLocalizations l10n = context.l10n;
  final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
  final Widget card = DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CupertinoActivityIndicator(
            color: AppColors.white,
            radius: 14,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.qrScannerCheckingIn,
            style: AppTypography.eventsChatMessageBody(
              textTheme,
              color: AppColors.textOnDark,
            ).copyWith(fontWeight: FontWeight.w600, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
  if (reduceMotion) {
    return card;
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: card,
    ),
  );
}
