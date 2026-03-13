import 'dart:convert';

import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistedCheckInSession {
  const PersistedCheckInSession({
    required this.eventId,
    required this.sessionId,
    required this.isOpen,
    required this.attendees,
  });

  final String eventId;
  final String sessionId;
  final bool isOpen;
  final List<CheckedInAttendee> attendees;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'sessionId': sessionId,
      'isOpen': isOpen,
      'attendees': attendees
          .map((CheckedInAttendee attendee) => attendee.toJson())
          .toList(growable: false),
    };
  }

  static PersistedCheckInSession? fromJson(Map<String, dynamic> json) {
    final String? eventId = json['eventId'] as String?;
    final String? sessionId = json['sessionId'] as String?;
    if (eventId == null ||
        eventId.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return null;
    }
    final List<dynamic> rawAttendees =
        json['attendees'] is List<dynamic> ? json['attendees'] as List<dynamic> : const <dynamic>[];
    final List<CheckedInAttendee> attendees = rawAttendees
        .whereType<Map<String, dynamic>>()
        .map(CheckedInAttendee.fromJson)
        .whereType<CheckedInAttendee>()
        .toList(growable: false);
    return PersistedCheckInSession(
      eventId: eventId,
      sessionId: sessionId,
      isOpen: json['isOpen'] == true,
      attendees: attendees,
    );
  }
}

class CheckInLocalCache {
  const CheckInLocalCache();

  static const String _sessionsCacheKey = 'events_checkin_sessions_v1';

  Future<List<PersistedCheckInSession>> readSessions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_sessionsCacheKey);
    if (raw == null || raw.isEmpty) {
      return const <PersistedCheckInSession>[];
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const <PersistedCheckInSession>[];
    }
    if (decoded is! List<dynamic>) {
      return const <PersistedCheckInSession>[];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PersistedCheckInSession.fromJson)
        .whereType<PersistedCheckInSession>()
        .toList(growable: false);
  }

  Future<void> writeSessions(List<PersistedCheckInSession> sessions) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> payload = sessions
        .map((PersistedCheckInSession session) => session.toJson())
        .toList(growable: false);
    await prefs.setString(_sessionsCacheKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsCacheKey);
  }
}
