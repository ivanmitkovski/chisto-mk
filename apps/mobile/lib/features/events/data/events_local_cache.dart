import 'dart:convert';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventsLocalCache {
  const EventsLocalCache();

  /// Unfiltered global list (backward compatible with older app versions).
  static const String legacyEventsCacheKey = 'events_cache_v1';

  /// Disk key for the active merged server params (null / empty → [legacyEventsCacheKey]).
  static String storageKeyForListParams(EcoEventSearchParams? params) {
    if (params == null || params.isEmpty) {
      return legacyEventsCacheKey;
    }
    return '${legacyEventsCacheKey}_${params.offlineListCacheSuffix}';
  }

  Future<List<EcoEvent>?> readEvents({EcoEventSearchParams? forActiveListParams}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = storageKeyForListParams(forActiveListParams);
    final String? raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! List<dynamic>) {
      return null;
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(EcoEvent.fromJson)
        .toList(growable: false);
  }

  Future<void> writeEvents(
    List<EcoEvent> events, {
    EcoEventSearchParams? forActiveListParams,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = storageKeyForListParams(forActiveListParams);
    final List<Map<String, dynamic>> payload =
        events.map((EcoEvent event) => event.toJson()).toList(growable: false);
    await prefs.setString(key, jsonEncode(payload));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyEventsCacheKey);
    for (final String key in prefs.getKeys()) {
      if (key.startsWith('${legacyEventsCacheKey}_')) {
        await prefs.remove(key);
      }
    }
  }
}
