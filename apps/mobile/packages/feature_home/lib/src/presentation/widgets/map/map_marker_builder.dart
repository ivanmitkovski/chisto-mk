import 'dart:math' as math;

import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/map_cluster_engine.dart';
import 'package:feature_home/src/presentation/widgets/map/animated_pollution_map_markers.dart';
import 'package:feature_home/src/presentation/widgets/map/cluster_bucket.dart';
import 'package:feature_home/src/presentation/widgets/map/map_layout_tokens.dart';
import 'package:feature_home/src/presentation/widgets/map/map_marker_entrance_cache.dart';
import 'package:feature_home/src/presentation/widgets/map/pollution_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

String mapMarkerMotionKeyForBucket(ClusterBucket bucket) {
  return bucket.sites.length == 1
      ? 's:${bucket.sites.first.id}'
      : 'c:${bucket.anchorId}';
}

LatLng mapMarkerPointForBucket(
  ClusterBucket bucket,
  Map<String, LatLng>? displayPoints, {
  Map<String, LatLng> spiderfyLegs = const <String, LatLng>{},
}) {
  if (bucket.sites.length == 1) {
    final String siteId = bucket.sites.first.id;
    final LatLng? leg = spiderfyLegs[siteId];
    if (leg != null) {
      return displayPoints?[mapMarkerMotionKeyForBucket(bucket)] ?? leg;
    }
  }
  if (displayPoints == null || displayPoints.isEmpty) {
    return bucket.center;
  }
  return displayPoints[mapMarkerMotionKeyForBucket(bucket)] ?? bucket.center;
}

List<Marker> buildMapMarkers({
  required List<ClusterBucket> clusters,
  required Map<String, LatLng> coords,
  required PollutionSite? selectedSite,
  required bool reduceAnimations,
  bool skipEntranceAnimations = false,
  required LatLng cameraCenter,
  required void Function(PollutionSite site, LatLng center) onSiteTap,
  required void Function(PollutionSite site) onSiteLongPress,
  required void Function(ClusterBucket bucket) onClusterTap,
  required MapMarkerEntranceCache entranceCache,
  LatLng? expansionOrigin,
  Set<String> expandingSiteIds = const <String>{},
  LatLng? expansionGhostCenter,
  Color? expansionGhostColor,
  int expansionGhostCount = 0,
  int expansionToken = 0,
  Map<String, LatLng>? markerDisplayPoints,
  Map<String, LatLng> spiderfyLegs = const <String, LatLng>{},
  Set<SpiderfyLine> spiderfyLines = const <SpiderfyLine>{},
}) {
  final List<Marker> markers = <Marker>[];

  // Ghost cluster rendered behind all other markers for smooth exit.
  if (!reduceAnimations &&
      expansionGhostCenter != null &&
      expansionGhostColor != null &&
      expansionGhostCount > 1) {
    final double ghostSize = MapLayoutTokens.clusterMarkerSize(
      expansionGhostCount,
    );
    markers.add(
      Marker(
        key: ValueKey<String>('ghost-$expansionToken'),
        point: expansionGhostCenter,
        width: ghostSize,
        height: ghostSize,
        child: ClusterGhostMarker(
          color: expansionGhostColor,
          count: expansionGhostCount,
        ),
      ),
    );
  }

  for (final ClusterBucket bucket in clusters) {
    if (bucket.sites.length == 1) {
      final PollutionSite site = bucket.sites.first;
      final bool selected = selectedSite?.id == site.id;
      final bool isExpanding = expandingSiteIds.contains(site.id);
      final bool playEntrance =
          !skipEntranceAnimations &&
          !reduceAnimations &&
          (isExpanding || entranceCache.consumeSingleSiteEntrance(site.id));
      final LatLng motionPoint = mapMarkerPointForBucket(
        bucket,
        markerDisplayPoints,
        spiderfyLegs: spiderfyLegs,
      );
      final Duration entranceDelay;
      if (!playEntrance) {
        entranceDelay = Duration.zero;
      } else if (isExpanding && expansionOrigin != null) {
        entranceDelay = _burstDelayForSite(motionPoint, expansionOrigin);
      } else {
        entranceDelay = Duration(
          milliseconds: mapEntranceDelayMsForPoint(
            motionPoint,
            cameraCenterLat: cameraCenter.latitude,
            cameraCenterLng: cameraCenter.longitude,
          ),
        );
      }
      markers.add(
        Marker(
          key: ValueKey<String>('single-${site.id}'),
          point: motionPoint,
          width: MapLayoutTokens.markerSize,
          height: MapLayoutTokens.markerSize,
          child: PollutionMarker(
            site: site,
            isSelected: selected,
            entranceDelay: entranceDelay,
            animate: playEntrance,
            burstEntrance: isExpanding && playEntrance,
            onTap: () => onSiteTap(site, motionPoint),
            onLongPress: () => onSiteLongPress(site),
          ),
        ),
      );
    } else {
      final int count = bucket.sites.length;
      final double size = MapLayoutTokens.clusterMarkerSize(count);
      final bool playEntrance =
          !skipEntranceAnimations &&
          !reduceAnimations &&
          entranceCache.consumeClusterEntrance(bucket.anchorId);
      final LatLng motionPoint = mapMarkerPointForBucket(
        bucket,
        markerDisplayPoints,
      );
      final Duration entranceDelay = !playEntrance
          ? Duration.zero
          : Duration(
              milliseconds: mapEntranceDelayMsForPoint(
                motionPoint,
                cameraCenterLat: cameraCenter.latitude,
                cameraCenterLng: cameraCenter.longitude,
              ),
            );
      markers.add(
        Marker(
          key: ValueKey<String>('cluster-${bucket.anchorId}'),
          point: motionPoint,
          width: size,
          height: size,
          child: ClusterMarker(
            count: count,
            bucket: bucket,
            entranceDelay: entranceDelay,
            animate: playEntrance,
            pulseEnabled:
                !skipEntranceAnimations && !reduceAnimations && count <= 28,
            onTap: () => onClusterTap(bucket),
          ),
        ),
      );
    }
  }
  return markers;
}

Duration _burstDelayForSite(LatLng sitePoint, LatLng origin) {
  final double dLat = (sitePoint.latitude - origin.latitude).abs();
  final double dLng = (sitePoint.longitude - origin.longitude).abs();
  final double distance = math.sqrt(dLat * dLat + dLng * dLng);
  const double maxDistance = 0.012;
  final int delayMs = (distance / maxDistance * 140).round().clamp(15, 180);
  return Duration(milliseconds: delayMs);
}
