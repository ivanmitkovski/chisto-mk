import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_site_maps.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

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
                  AppHaptics.tap();
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
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () async {
                      AppHaptics.softTransition();
                      Navigator.of(sheetCtx).pop();
                      await showEventSiteMapsSheet(
                        context,
                        lat: event.siteLat!,
                        lng: event.siteLng!,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                    child: Text(
                      sheetCtx.l10n.eventsDetailOpenInMaps,
                      style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
