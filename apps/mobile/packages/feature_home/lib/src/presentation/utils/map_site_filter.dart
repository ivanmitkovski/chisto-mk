import 'package:feature_home/src/data/map_regions/macedonia_map_regions.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  final String statusCode = mapStatusCodeFromUnknown(
    site.statusCode ?? site.statusLabel,
  );
  if (statusCode == mapStatusArchived) {
    if (!filter.includeArchived) {
      return false;
    }
  } else if (!activeStatusCodes.contains(statusCode)) {
    return false;
  }
  final String ptCode = reportPollutionTypeCodeFromUnknown(site.pollutionType);
  if (!activePollutionTypeCodes.contains(ptCode)) {
    return false;
  }
  return _siteInGeo(site, geoBounds);
}

bool mapFilterHasNonDefault(MapFilterState filter) {
  return filter.geoAreaId != null ||
      filter.includeArchived ||
      !setEquals(filter.activeStatuses, mapFilterDefaultStatuses) ||
      !setEquals(filter.activePollutionTypes, reportPollutionTypeCodes.toSet());
}

int mapFilterPreviewCount(List<PollutionSite> sites, MapFilterState filter) {
  final LatLngBounds? geoBounds = MacedoniaMapRegions.boundsFor(
    filter.geoAreaId,
  );
  return sites
      .where(
        (PollutionSite site) =>
            pollutionSiteMatchesMapFilter(site, filter, geoBounds: geoBounds),
      )
      .length;
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
