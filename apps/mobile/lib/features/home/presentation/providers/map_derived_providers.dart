import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/data/map_regions/macedonia_map_regions.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_site_corpus_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_sites_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/utils/map_site_filter.dart';

/// Sites visible under current map filter chips.
final mapFilteredSitesProvider = Provider<List<PollutionSite>>((Ref ref) {
  final List<PollutionSite> sites = ref.watch(
    mapSitesNotifierProvider.select((MapSitesState s) => s.sites),
  );
  final MapFilterState filter = ref.watch(mapFilterNotifierProvider);
  final LatLngBounds? geoBounds = MacedoniaMapRegions.boundsFor(filter.geoAreaId);
  return sites
      .where(
        (PollutionSite s) =>
            pollutionSiteMatchesMapFilter(s, filter, geoBounds: geoBounds),
      )
      .toList();
});

/// Local search pool: viewport working set merged with filter-corpus prefetch
/// (deduped by id; viewport order preserved first).
final mapSearchLocalPoolProvider = Provider<List<PollutionSite>>((Ref ref) {
  final List<PollutionSite> viewport = ref.watch(mapFilteredSitesProvider);
  final MapSiteCorpusState corpus = ref.watch(mapSiteCorpusNotifierProvider);
  final Map<String, PollutionSite> byId = <String, PollutionSite>{};
  for (final PollutionSite s in viewport) {
    byId[s.id] = s;
  }
  for (final PollutionSite s in corpus.sites) {
    byId.putIfAbsent(s.id, () => s);
  }
  return byId.values.toList();
});

/// Search policy: local pool (viewport + filter-aligned corpus).
final mapSearchDatasetProvider = Provider<List<PollutionSite>>((Ref ref) {
  return ref.watch(mapSearchLocalPoolProvider);
});

/// Stable [siteId] → coordinate map for markers, heatmap, and preview distance.
final mapSiteCoordinatesProvider = Provider<Map<String, LatLng>>((Ref ref) {
  final List<PollutionSite> sites =
      ref.watch(mapSitesNotifierProvider.select((MapSitesState s) => s.sites));
  final Map<String, LatLng> coords = <String, LatLng>{};
  for (final PollutionSite site in sites) {
    if (site.latitude != null && site.longitude != null) {
      coords[site.id] = LatLng(site.latitude!, site.longitude!);
    }
  }
  return coords;
});
