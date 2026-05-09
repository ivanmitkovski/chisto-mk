import 'package:flutter/material.dart' show Color;
import 'package:latlong2/latlong.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

/// Helper for clustering pollution sites by geographic proximity.
class ClusterBucket {
  ClusterBucket({required LatLng center, required this.sites})
      : _center = center;

  LatLng _center;
  final List<PollutionSite> sites;

  LatLng get center => _center;

  /// Stable across zoom/pan recomputations for the same member sites (sorted ids).
  String get stableClusterId {
    if (sites.isEmpty) {
      return 'empty';
    }
    if (sites.length == 1) {
      return sites.single.id;
    }
    final List<String> ids = sites.map((PollutionSite s) => s.id).toList()
      ..sort();
    return ids.join('|');
  }

  void addSite(PollutionSite site, LatLng point) {
    final int n = sites.length;
    _center = LatLng(
      (_center.latitude * n + point.latitude) / (n + 1),
      (_center.longitude * n + point.longitude) / (n + 1),
    );
    sites.add(site);
  }

  Color get dominantColor {
    final Map<String, int> counts = <String, int>{};
    for (final PollutionSite s in sites) {
      counts[s.statusLabel] = (counts[s.statusLabel] ?? 0) + 1;
    }
    String dominant = sites.first.statusLabel;
    int max = 0;
    for (final MapEntry<String, int> e in counts.entries) {
      if (e.value > max) {
        max = e.value;
        dominant = e.key;
      }
    }
    return sites
        .firstWhere((PollutionSite s) => s.statusLabel == dominant)
        .statusColor;
  }
}
