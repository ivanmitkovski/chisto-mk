import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Same rules as [mapFilteredSitesProvider], extracted for corpus + search reuse.
bool pollutionSiteMatchesMapFilter(
  PollutionSite site,
  MapFilterState filter, {
  LatLngBounds? geoBounds,
}) {
  final Set<String> activeStatusCodes = filter.activeStatuses
      .map(mapStatusCodeFromUnknown)
      .toSet();
  final Set<String> activePollutionTypeCodes = filter.activePollutionTypes
      .map(reportPollutionTypeCodeFromUnknown)
      .toSet();
  final String statusCode =
      mapStatusCodeFromUnknown(site.statusCode ?? site.statusLabel);
  if (!activeStatusCodes.contains(statusCode)) {
    return false;
  }
  final String ptCode = reportPollutionTypeCodeFromUnknown(site.pollutionType);
  if (!activePollutionTypeCodes.contains(ptCode)) {
    return false;
  }
  return _siteInGeo(site, geoBounds);
}

bool _siteInGeo(PollutionSite site, LatLngBounds? geoBounds) {
  if (geoBounds == null) {
    return true;
  }
  final double? lat = site.latitude;
  final double? lng = site.longitude;
  if (lat == null || lng == null) {
    return false;
  }
  return geoBounds.contains(LatLng(lat, lng));
}
