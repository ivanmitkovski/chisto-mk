import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

String _mobileScannerErrorBody(
  MobileScannerErrorCode code,
  AppLocalizations l10n,
) {
  switch (code) {
    case MobileScannerErrorCode.permissionDenied:
      return l10n.qrScannerHintCameraBlocked;
    case MobileScannerErrorCode.unsupported:
      return l10n.qrScannerCameraUnavailableFeedback;
    default:
      return l10n.qrScannerCameraUnavailableFeedback;
  }
}

/// Permission-denied and other camera errors from [mobile_scanner].
/// Used by [AttendeeQrScannerScreen] and widget tests.
Widget attendeeQrScannerCameraErrorLayer(
  BuildContext context, {
  required MobileScannerErrorCode errorCode,
  required VoidCallback onRetryCamera,
  required VoidCallback onEnterManually,
}) {
  final TextTheme textTheme = Theme.of(context).textTheme;
  final AppLocalizations l10n = context.l10n;
  final String detail = _mobileScannerErrorBody(errorCode, l10n);
  return ColoredBox(
    color: AppColors.black,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Semantics(
              container: true,
              label: '${l10n.qrScannerCameraErrorTitle}. $detail',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: AppColors.accentWarning,
                    size: 44,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.qrScannerCameraErrorTitle,
                    style: AppTypography.eventsHeroCardTitle(textTheme).copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail,
                    style: AppTypography.eventsHeroCardMeta(textTheme).copyWith(
                      color: AppColors.textOnDarkMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                Semantics(
                  button: true,
                  label: l10n.qrScannerRetryCamera,
                  child: CupertinoButton(
                    onPressed: onRetryCamera,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      l10n.qrScannerRetryCamera,
                      style: AppTypography.eventsTextLinkEmphasis(textTheme)
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.qrScannerEnterManually,
                  child: CupertinoButton(
                    onPressed: onEnterManually,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      l10n.qrScannerEnterManually,
                      style: AppTypography.eventsTextLinkEmphasis(textTheme)
                          .copyWith(color: AppColors.textOnDark),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
