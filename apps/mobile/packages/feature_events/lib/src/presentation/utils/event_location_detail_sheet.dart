import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/utils/event_site_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet: full site name / address, copy, optional maps.
Future<void> showEventLocationDetailSheet(
  BuildContext context, {
  required EcoEvent event,
}) {
  return AppBottomSheet.show<void>(
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
                style: AppTypography.eventsLocationSheetAddress(
                  Theme.of(sheetCtx).textTheme,
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
