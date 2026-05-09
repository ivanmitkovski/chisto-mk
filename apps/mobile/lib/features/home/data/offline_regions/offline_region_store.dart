import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'offline_region_model.dart';

/// Manages Hive-backed storage for offline map regions, tiles, and site data.
///
/// Three boxes:
/// - `offline_regions`  – region metadata stored as JSON strings keyed by region ID.
/// - `offline_tiles`    – raw MVT tile bytes keyed by `'$z/$x/$y'`.
/// - `offline_sites`    – site list JSON keyed by region ID.
class OfflineRegionStore {
  static const String _regionsBoxName = 'offline_regions';
  static const String _tilesBoxName = 'offline_tiles';
  static const String _sitesBoxName = 'offline_sites';

  /// 200 MB cap for all offline data combined.
  static const int storageCap = 200 * 1024 * 1024;

  Box<String>? _regionsBox;
  /// Raw MVT bytes; [Box<dynamic>] avoids Hive type issues with binary payloads.
  Box<dynamic>? _tilesBox;
  Box<String>? _sitesBox;

  bool get isInitialized =>
      _regionsBox?.isOpen == true &&
      _tilesBox?.isOpen == true &&
      _sitesBox?.isOpen == true;

  Future<void> init() async {
    _regionsBox = await Hive.openBox<String>(_regionsBoxName);
    _tilesBox = await Hive.openBox<dynamic>(_tilesBoxName);
    _sitesBox = await Hive.openBox<String>(_sitesBoxName);
  }

  // ---------------------------------------------------------------------------
  // Region metadata
  // ---------------------------------------------------------------------------

  Future<void> saveRegion(OfflineRegion region) async {
    final String json = jsonEncode(region.toJson());
    await _regionsBox!.put(region.id, json);
  }

  List<OfflineRegion> getRegions() {
    final Box<String> box = _regionsBox!;
    final List<OfflineRegion> regions = <OfflineRegion>[];
    for (final String key in box.keys.cast<String>()) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(box.get(key)!) as Map<String, dynamic>;
        regions.add(OfflineRegion.fromJson(json));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[OfflineRegionStore] corrupt region entry "$key": $e');
        }
      }
    }
    return regions;
  }

  Future<void> deleteRegion(String id) async {
    await _regionsBox!.delete(id);

    // Remove tiles that belong to this region (keyed by region prefix).
    final Box<dynamic> tiles = _tilesBox!;
    final List<String> tilesToRemove = tiles.keys
        .cast<String>()
        .where((String k) => k.startsWith('$id/'))
        .toList();
    for (final String key in tilesToRemove) {
      await tiles.delete(key);
    }

    await _sitesBox!.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Tile storage – keys are formatted as '$regionId/$z/$x/$y'
  // ---------------------------------------------------------------------------

  Future<void> saveTile(
    String regionId,
    int z,
    int x,
    int y,
    Uint8List bytes,
  ) async {
    await _tilesBox!.put('$regionId/$z/$x/$y', bytes);
  }

  /// Raw tile bytes for MVT decode, or null if missing / legacy corrupt entry.
  Uint8List? getTile(String regionId, int z, int x, int y) {
    final Object? raw = _tilesBox!.get('$regionId/$z/$x/$y');
    if (raw is Uint8List) {
      return raw;
    }
    if (raw is List<int>) {
      return Uint8List.fromList(List<int>.from(raw));
    }
    return null;
  }

  bool hasTile(String regionId, int z, int x, int y) {
    return _tilesBox!.containsKey('$regionId/$z/$x/$y');
  }

  // ---------------------------------------------------------------------------
  // Site JSON storage
  // ---------------------------------------------------------------------------

  Future<void> saveSitesJson(String regionId, String json) async {
    await _sitesBox!.put(regionId, json);
  }

  String? getSitesJson(String regionId) {
    return _sitesBox!.get(regionId);
  }

  // ---------------------------------------------------------------------------
  // Storage accounting
  // ---------------------------------------------------------------------------

  int get totalSizeBytes {
    int total = 0;
    for (final String region in _regionsBox!.keys.cast<String>()) {
      final String? data = _regionsBox!.get(region);
      if (data != null) {
        total += data.length;
      }
    }
    for (final String key in _tilesBox!.keys.cast<String>()) {
      final Object? raw = _tilesBox!.get(key);
      if (raw is Uint8List) {
        total += raw.length;
      } else if (raw is List<int>) {
        total += raw.length;
      }
    }
    for (final String key in _sitesBox!.keys.cast<String>()) {
      final String? data = _sitesBox!.get(key);
      if (data != null) {
        total += data.length;
      }
    }
    return total;
  }

  /// Evicts the oldest-refreshed region when total storage exceeds the cap.
  Future<void> evictLru() async {
    while (totalSizeBytes > storageCap) {
      final List<OfflineRegion> regions = getRegions();
      if (regions.isEmpty) break;

      regions.sort((OfflineRegion a, OfflineRegion b) {
        final DateTime aTime =
            a.lastRefreshed ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.lastRefreshed ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

      await deleteRegion(regions.first.id);
    }
  }
}
