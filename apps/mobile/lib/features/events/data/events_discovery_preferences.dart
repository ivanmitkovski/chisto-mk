import 'dart:convert';

import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PRIVACY: Stores user search history in SharedPreferences. Must be cleared on logout.
class EventsDiscoveryPreferences {
  const EventsDiscoveryPreferences();

  static const String _recentSearchesKey = 'events_discovery_recent_searches_v1';
  static const String _activeFilterKey = 'events_discovery_active_filter_v1';
  static const String _calendarViewPreferredKey =
      'events_discovery_calendar_view_preferred_v1';
  static const int _maxRecentSearches = 8;

  Future<List<String>> readRecentSearches() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_recentSearchesKey);
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const <String>[];
    }
    if (decoded is! List<dynamic>) {
      return const <String>[];
    }
    return decoded
        .whereType<String>()
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> writeRecentSearches(List<String> queries) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> normalized = <String>[];
    for (final String raw in queries) {
      final String q = raw.trim();
      if (q.isEmpty) {
        continue;
      }
      final String key = q.toLowerCase();
      final bool exists = normalized.any((String e) => e.toLowerCase() == key);
      if (!exists) {
        normalized.add(q);
      }
      if (normalized.length >= _maxRecentSearches) {
        break;
      }
    }
    await prefs.setString(_recentSearchesKey, jsonEncode(normalized));
  }

  /// Last selected events feed chip (persisted across sessions).
  Future<EcoEventFilter> readActiveFilter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_activeFilterKey);
    if (raw == null || raw.trim().isEmpty) {
      return EcoEventFilter.all;
    }
    for (final EcoEventFilter filter in EcoEventFilter.values) {
      if (filter.name == raw.trim()) {
        return filter;
      }
    }
    return EcoEventFilter.all;
  }

  Future<void> writeActiveFilter(EcoEventFilter filter) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeFilterKey, filter.name);
  }

  /// Whether the events feed should open in calendar mode (default: list).
  Future<bool> readCalendarViewPreferred() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_calendarViewPreferredKey) ?? false;
  }

  Future<void> writeCalendarViewPreferred(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calendarViewPreferredKey, value);
  }
}
