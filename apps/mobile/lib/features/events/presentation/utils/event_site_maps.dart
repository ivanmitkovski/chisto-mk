import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/directions_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/device_platform.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows Apple/Google map options and opens the chosen app for [lat]/[lng].
Future<void> showEventSiteMapsSheet(
  BuildContext context, {
  required double lat,
  required double lng,
}) async {
  AppHaptics.softTransition();
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    barrierColor: AppColors.overlay,
    backgroundColor: AppColors.transparent,
    builder: (BuildContext sheetContext) {
      return DirectionsSheet(
        mode: DirectionsSheetMode.viewLocation,
        onAppleMapsTap: () {
          Navigator.of(sheetContext).pop();
          unawaited(
            _launchMapsAt(
              context,
              lat: lat,
              lng: lng,
              useAppleMaps: true,
            ),
          );
        },
        onGoogleMapsTap: () {
          Navigator.of(sheetContext).pop();
          unawaited(
            _launchMapsAt(
              context,
              lat: lat,
              lng: lng,
              useAppleMaps: false,
            ),
          );
        },
        onDismiss: () => Navigator.of(sheetContext).pop(),
      );
    },
  );
}

Future<void> _launchMapsAt(
  BuildContext context, {
  required double lat,
  required double lng,
  required bool useAppleMaps,
}) async {
  final String destStr = '$lat,$lng';
  final Uri url = useAppleMaps && DevicePlatform.isIOS
      ? Uri.parse('https://maps.apple.com/?ll=$destStr')
      : Uri.parse('https://www.google.com/maps/search/?api=1&query=$destStr');
  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.siteDetailOpenMapsFailedSnack,
        type: AppSnackType.warning,
      );
    }
  } on Object {
    if (context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.siteDetailOpenMapsFailedSnack,
        type: AppSnackType.warning,
      );
    }
  }
}
