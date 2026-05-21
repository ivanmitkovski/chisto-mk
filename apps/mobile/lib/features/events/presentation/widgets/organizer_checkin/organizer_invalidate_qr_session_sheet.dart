import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';

/// Confirms invalidating the organizer QR session (rotates codes).
Future<bool?> showOrganizerInvalidateQrSessionSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
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
