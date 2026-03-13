import 'dart:convert';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventsLocalCache {
  const EventsLocalCache();

  static const String _eventsCacheKey = 'events_cache_v1';

  Future<List<EcoEvent>?> readEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_eventsCacheKey);
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

  Future<void> writeEvents(List<EcoEvent> events) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> payload =
        events.map((EcoEvent event) => event.toJson()).toList(growable: false);
    await prefs.setString(_eventsCacheKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventsCacheKey);
  }
}
