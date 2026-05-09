import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/core/network/api_client.dart';

import 'offline_region_model.dart';
import 'offline_region_store.dart';

/// Downloads map tiles and site data for an [OfflineRegion] and persists them
/// into the [OfflineRegionStore].
///
/// Tiles are fetched for zoom levels 8–14 within the region bounding box.
/// Up to [_concurrency] tile downloads run in parallel. Individual tile
/// failures are silently skipped so one bad tile doesn't abort the region.
class OfflineRegionDownloader {
  OfflineRegionDownloader({
    required ApiClient apiClient,
    required OfflineRegionStore store,
  })  : _apiClient = apiClient,
        _store = store;

  final ApiClient _apiClient;
  final OfflineRegionStore _store;

  static const int _minZoom = 8;
  static const int _maxZoom = 14;
  static const int _concurrency = 4;

  bool _cancelled = false;

  void cancelDownload() {
    _cancelled = true;
  }

  /// Downloads tiles and site data for [region].
  ///
  /// [progress] is updated from 0.0 → 1.0 as tiles complete.
  /// Tiles already present in the store are skipped (supports resume).
  /// Returns the updated [OfflineRegion] with final byte/count stats.
  Future<OfflineRegion> downloadRegion(
    OfflineRegion region, {
    ValueNotifier<double>? progress,
  }) async {
    _cancelled = false;

    // Compute all tile coordinates for the region bbox across z levels.
    final List<_TileCoord> allTiles = <_TileCoord>[];
    for (int z = _minZoom; z <= _maxZoom; z++) {
      final int xMin = _lngToTileX(region.minLng, z);
      final int xMax = _lngToTileX(region.maxLng, z);
      final int yMin = _latToTileY(region.maxLat, z);
      final int yMax = _latToTileY(region.minLat, z);
      for (int x = xMin; x <= xMax; x++) {
        for (int y = yMin; y <= yMax; y++) {
          allTiles.add(_TileCoord(z, x, y));
        }
      }
    }

    // Filter out already-downloaded tiles to support resume.
    final List<_TileCoord> pending = allTiles
        .where((_TileCoord t) => !_store.hasTile(region.id, t.z, t.x, t.y))
        .toList();

    final int totalTiles = allTiles.length;
    int completedTiles = totalTiles - pending.length;
    int totalBytes = 0;

    // Download tiles in parallel with bounded concurrency.
    final List<Future<void>> workers = <Future<void>>[];
    int nextIndex = 0;

    Future<void> worker() async {
      while (!_cancelled) {
        final int index;
        // Grab next tile index atomically via closure capture.
        if (nextIndex >= pending.length) break;
        index = nextIndex++;

        final _TileCoord tile = pending[index];
        try {
          final ApiBytesResponse response = await _apiClient.getBytes(
            '/sites/map/tiles/${tile.z}/${tile.x}/${tile.y}.mvt',
          );
          if (_cancelled) return;

          if (response.statusCode != 200 || response.bytes.isEmpty) {
            continue;
          }
          await _store.saveTile(
            region.id,
            tile.z,
            tile.x,
            tile.y,
            response.bytes,
          );
          totalBytes += response.bytes.length;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[OfflineDownloader] tile ${tile.z}/${tile.x}/${tile.y} failed: $e',
            );
          }
        }
        completedTiles++;
        final double p =
            totalTiles > 0 ? completedTiles / totalTiles : 1.0;
        progress?.value = p.clamp(0.0, 0.95);
      }
    }

    for (int i = 0; i < _concurrency; i++) {
      workers.add(worker());
    }
    await Future.wait(workers);

    if (_cancelled) {
      return region.copyWith(downloadProgress: 0.0);
    }

    // Download site data for the region.
    int siteCount = 0;
    try {
      final ApiResponse sitesResponse = await _apiClient.get(
        '/sites/map'
        '?minLat=${region.minLat}'
        '&maxLat=${region.maxLat}'
        '&minLng=${region.minLng}'
        '&maxLng=${region.maxLng}'
        '&limit=5000'
        '&detail=lite',
      );
      if (!_cancelled && sitesResponse.body != null) {
        await _store.saveSitesJson(region.id, sitesResponse.body!);
        totalBytes += sitesResponse.body!.length;
        if (sitesResponse.json != null) {
          final dynamic data = sitesResponse.json!['data'];
          if (data is List) {
            siteCount = data.length;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OfflineDownloader] site data download failed: $e');
      }
    }

    progress?.value = 1.0;

    final OfflineRegion updated = region.copyWith(
      tileCount: totalTiles,
      siteCount: siteCount,
      sizeBytes: totalBytes,
      lastRefreshed: DateTime.now(),
      downloadProgress: 1.0,
    );
    await _store.saveRegion(updated);
    await _store.evictLru();

    return updated;
  }

  // ---------------------------------------------------------------------------
  // Slippy-map tile coordinate math
  // ---------------------------------------------------------------------------

  static int _lngToTileX(double lng, int z) {
    return ((lng + 180.0) / 360.0 * (1 << z)).floor();
  }

  static int _latToTileY(double lat, int z) {
    final double latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            (1 << z))
        .floor();
  }
}

class _TileCoord {
  const _TileCoord(this.z, this.x, this.y);
  final int z;
  final int x;
  final int y;
}
