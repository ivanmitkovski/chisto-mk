import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_site_maps.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';

/// Bottom sheet: full site name / address, copy, optional maps.
Future<void> showEventLocationDetailSheet(
  BuildContext context, {
  required EcoEvent event,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (BuildContext sheetCtx) {
      final bool hasCoords = event.siteLat != null && event.siteLng != null;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
        ),
        child: ReportSheetScaffold(
          title: sheetCtx.l10n.eventsDetailLocationTitle,
          fitToContent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                event.siteName,
                style: Theme.of(sheetCtx).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: sheetCtx.l10n.eventsDetailCopyAddress,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: event.siteName));
                  Navigator.of(sheetCtx).pop();
                  AppSnack.show(
                    context,
                    message: context.l10n.eventsDetailAddressCopied,
                    type: AppSnackType.success,
                  );
                },
              ),
              if (hasCoords) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppButton.outlined(
                  label: sheetCtx.l10n.eventsDetailOpenInMaps,
                  onPressed: () async {
                    Navigator.of(sheetCtx).pop();
                    await showEventSiteMapsSheet(
                      context,
                      lat: event.siteLat!,
                      lng: event.siteLng!,
                    );
                  },
                  expand: true,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
