import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists last map search phrases (privacy: local device only).
class MapSearchRecentsStore {
  MapSearchRecentsStore._();

  static const String _key = 'map_search_recent_v1';
  static const int _maxItems = 5;

  static List<String> readSync(SharedPreferences prefs) {
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <String>[];
      }
      return decoded
          .map((Object? e) => e.toString().trim())
          .where((String s) => s.isNotEmpty)
          .take(_maxItems)
          .toList();
    } on Object catch (_) {
      return const <String>[];
    }
  }

  static Future<void> add(SharedPreferences prefs, String term) async {
    final String t = term.trim();
    if (t.length < 2) {
      return;
    }
    final List<String> next =
        MapSearchRecentsStore.readSync(prefs).where((String s) => s.toLowerCase() != t.toLowerCase()).toList()
          ..insert(0, t);
    if (next.length > _maxItems) {
      next.removeRange(_maxItems, next.length);
    }
    await prefs.setString(_key, jsonEncode(next));
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(_key);
  }
}
