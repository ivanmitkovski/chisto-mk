import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Confirms invalidating the organizer QR session (rotates codes).
Future<bool?> showOrganizerInvalidateQrSessionSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: (BuildContext sheetCtx) {
      final AppLocalizations l10n = sheetCtx.l10n;
      final TextTheme sheetTextTheme = Theme.of(sheetCtx).textTheme;
      return ReportSheetScaffold(
        fitToContent: true,
        title: l10n.eventsOrganizerInvalidateQrTitle,
        subtitle: l10n.eventsOrganizerInvalidateQrSubtitle,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: l10n.commonClose,
          onTap: () {
            AppHaptics.tap();
            Navigator.of(sheetCtx).pop(false);
          },
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(sheetCtx).pop(false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusPill,
                    ),
                  ),
                ),
                child: Text(
                  l10n.commonCancel,
                  style: sheetTextTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.eventsOrganizerInvalidateQrTitle,
              enabled: true,
              onPressed: () {
                AppHaptics.tap();
                Navigator.of(sheetCtx).pop(true);
              },
            ),
          ],
        ),
        child: const SizedBox.shrink(),
      );
    },
  );
}
