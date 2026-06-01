import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:flutter/material.dart' show Color;
import 'package:latlong2/latlong.dart';

/// Helper for clustering pollution sites by geographic proximity.
class ClusterBucket {
  ClusterBucket({
    required LatLng center,
    required this.sites,
    required this.anchorId,
  }) : _center = center;

  LatLng _center;
  final List<PollutionSite> sites;

  /// Seed-stable id: id of the first site that opened this bucket (lowest id
  /// among members when sites are processed in sorted order).
  final String anchorId;

  LatLng get center => _center;

  /// Legacy membership hash — debug/tests only; do not use as render key.
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
    String? dominant;
    int max = 0;
    for (final MapEntry<String, int> e in counts.entries) {
      if (e.value > max) {
        max = e.value;
        dominant = e.key;
      } else if (e.value == max && dominant != null) {
        // Tie-break: lower site id wins so +1 member cannot flip color randomly.
        final PollutionSite candidate = sites.firstWhere(
          (PollutionSite s) => s.statusLabel == e.key,
        );
        final PollutionSite current = sites.firstWhere(
          (PollutionSite s) => s.statusLabel == dominant,
        );
        if (candidate.id.compareTo(current.id) < 0) {
          dominant = e.key;
        }
      }
    }
    dominant ??= sites.first.statusLabel;
    return sites
        .firstWhere((PollutionSite s) => s.statusLabel == dominant)
        .statusColor;
  }
}
