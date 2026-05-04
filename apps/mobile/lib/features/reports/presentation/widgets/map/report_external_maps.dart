import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/map/directions_sheet.dart';
import 'package:chisto_mobile/shared/utils/device_platform.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Shows Apple/Google choice for viewing [latitude]/[longitude] in an external maps app.
Future<void> showReportViewLocationDirectionsSheet({
  required BuildContext context,
  required double latitude,
  required double longitude,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (BuildContext sheetContext) {
      return DirectionsSheet(
        mode: DirectionsSheetMode.viewLocation,
        onAppleMapsTap: () {
          Navigator.of(sheetContext).pop();
          unawaited(
            launchReportCoordinatesInExternalMap(
              context: context,
              latitude: latitude,
              longitude: longitude,
              useAppleMaps: true,
            ),
          );
        },
        onGoogleMapsTap: () {
          Navigator.of(sheetContext).pop();
          unawaited(
            launchReportCoordinatesInExternalMap(
              context: context,
              latitude: latitude,
              longitude: longitude,
              useAppleMaps: false,
            ),
          );
        },
        onDismiss: () => Navigator.of(sheetContext).pop(),
      );
    },
  );
}

Future<void> launchReportCoordinatesInExternalMap({
  required BuildContext context,
  required double latitude,
  required double longitude,
  required bool useAppleMaps,
}) async {
  final String destStr = '$latitude,$longitude';
  final Uri url = useAppleMaps && DevicePlatform.isIOS
      ? Uri.parse('https://maps.apple.com/?ll=$destStr')
      : Uri.parse('https://www.google.com/maps/search/?api=1&query=$destStr');
  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.mapOpenMapsFailed,
        type: AppSnackType.warning,
      );
    }
  } catch (_) {
    if (context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.mapOpenMapsFailed,
        type: AppSnackType.warning,
      );
    }
  }
}
