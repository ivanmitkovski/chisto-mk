import 'package:feature_home/src/presentation/widgets/map/map_marker_entrance_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Map-scoped entrance animation cache (not a global singleton).
final mapMarkerEntranceCacheProvider = Provider<MapMarkerEntranceCache>(
  (Ref ref) => MapMarkerEntranceCache(),
);
