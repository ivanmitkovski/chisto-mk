import 'dart:convert';

import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists which events the user has added to their device calendar.
///
/// OS calendars cannot be queried reliably without invasive permissions, so we
/// record a successful [EventCalendarExport] flow (native sheet launched OK) keyed
/// by event id + schedule fingerprint. If the event time changes, the fingerprint
/// no longer matches and the user can add again.
class EventCalendarAddedStore {
  EventCalendarAddedStore._();

  static const String _prefsKey = 'event_calendar_added_v1';

  static Future<bool> isMarkedAdded(EcoEvent event) async {
    final String? stored = await _readFingerprint(event.id);
    if (stored == null) {
      return false;
    }
    return stored == fingerprintFor(event);
  }

  /// Clears every persisted calendar-add marker on logout.
  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static Future<void> markAdded(EcoEvent event) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, String> all = await _readAll(prefs);
    all[event.id] = fingerprintFor(event);
    await prefs.setString(_prefsKey, jsonEncode(all));
  }

  /// Stable signature for the calendar entry we exported (detect schedule edits).
  static String fingerprintFor(EcoEvent event) {
    return '${event.startDateTime.toUtc().millisecondsSinceEpoch}:'
        '${event.endDateTime.toUtc().millisecondsSinceEpoch}:'
        '${event.title.trim()}';
  }

  static Future<String?> _readFingerprint(String eventId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, String> all = await _readAll(prefs);
    return all[eventId];
  }

  static Future<Map<String, String>> _readAll(SharedPreferences prefs) async {
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, String>{};
      }
      return Map<String, String>.from(
        decoded.map(
          (Object? key, Object? value) =>
              MapEntry(key.toString(), value.toString()),
        ),
      );
    } catch (_) {
      return <String, String>{};
    }
  }
}
