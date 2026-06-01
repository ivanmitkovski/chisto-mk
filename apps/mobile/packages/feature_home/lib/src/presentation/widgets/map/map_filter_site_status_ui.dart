import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:flutter/material.dart';

String mapFilterSiteStatusDisplay(AppLocalizations l10n, String statusKey) {
  return mapStatusDisplay(l10n, mapStatusCodeFromUnknown(statusKey));
}

Color mapFilterSiteStatusColor(String statusKey) {
  return mapStatusColor(mapStatusCodeFromUnknown(statusKey));
}
