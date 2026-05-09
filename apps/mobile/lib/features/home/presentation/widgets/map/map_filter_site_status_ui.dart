import 'package:flutter/material.dart';

import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';

String mapFilterSiteStatusDisplay(AppLocalizations l10n, String statusKey) {
  return mapStatusDisplay(l10n, mapStatusCodeFromUnknown(statusKey));
}

Color mapFilterSiteStatusColor(String statusKey) {
  return mapStatusColor(mapStatusCodeFromUnknown(statusKey));
}
