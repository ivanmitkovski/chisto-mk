import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Confirms invalidating the organizer QR session (rotates codes).
Future<bool?> showOrganizerInvalidateQrSessionSheet(BuildContext context) {
  return AppBottomSheet.show<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: (BuildContext sheetCtx) {
      final AppLocalizations l10n = sheetCtx.l10n;
      return ReportSheetScaffold(
        fitToContent: true,
        title: l10n.eventsOrganizerInvalidateQrTitle,
        subtitle: l10n.eventsOrganizerInvalidateQrSubtitle,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: l10n.commonClose,
          onTap: () {
            Navigator.of(sheetCtx).pop(false);
          },
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppButton.outlined(
              label: l10n.commonCancel,
              onPressed: () {
                Navigator.of(sheetCtx).pop(false);
              },
              expand: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.eventsOrganizerInvalidateQrTitle,
              enabled: true,
              onPressed: () {
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
