part of 'map_marker_entrance_cache.dart';

@visibleForTesting
MapMarkerEntranceCache createMapMarkerEntranceCacheForTest() {
  return MapMarkerEntranceCache();
}

@visibleForTesting
void resetMapMarkerEntranceCacheForTest(MapMarkerEntranceCache cache) {
  cache._resetForTest();
}
