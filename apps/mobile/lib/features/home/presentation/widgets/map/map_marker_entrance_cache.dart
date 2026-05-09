import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';

/// Remembers which markers already played their first entrance so pan/zoom
/// cluster recomputes do not re-run scale-in animations.
final class MapMarkerEntranceCache {
  MapMarkerEntranceCache._();

  static final MapMarkerEntranceCache instance = MapMarkerEntranceCache._();

  final Set<String> _singleSiteIds = <String>{};
  final Set<String> _clusterIds = <String>{};

  /// [Set.add] returns true only when the id was not yet present.
  bool consumeSingleSiteEntrance(String siteId) => _singleSiteIds.add(siteId);

  bool consumeClusterEntrance(String stableClusterId) =>
      _clusterIds.add(stableClusterId);

  /// Sorted stable cluster ids — changes when zoom/pan/filter reflows membership.
  static String clusterPartitionSignature(List<ClusterBucket> buckets) {
    if (buckets.isEmpty) {
      return '';
    }
    final List<String> parts = buckets.map((ClusterBucket b) => b.stableClusterId).toList()
      ..sort();
    return parts.join('\x1e');
  }

  /// When the cluster partition changes, allow a soft scale-in for pins that
  /// were inside a multi-site cluster and are now shown as individual markers.
  void applyReclusterEntranceInvalidations({
    required List<ClusterBucket> previous,
    required List<ClusterBucket> current,
  }) {
    if (previous.isEmpty || current.isEmpty) {
      return;
    }
    final Set<String> inMultiBefore = <String>{};
    for (final ClusterBucket b in previous) {
      if (b.sites.length <= 1) {
        continue;
      }
      for (final PollutionSite s in b.sites) {
        inMultiBefore.add(s.id);
      }
    }
    for (final ClusterBucket b in current) {
      if (b.sites.length != 1) {
        continue;
      }
      final String id = b.sites.first.id;
      if (inMultiBefore.contains(id)) {
        _singleSiteIds.remove(id);
      }
    }
  }

  /// Resets entrance state for [siteIds] so they replay their scale-in
  /// when emerging from a cluster expansion.
  void resetForClusterExpansion(Iterable<String> siteIds) {
    _singleSiteIds.removeAll(siteIds);
  }

  @visibleForTesting
  void clear() {
    _singleSiteIds.clear();
    _clusterIds.clear();
  }
}
