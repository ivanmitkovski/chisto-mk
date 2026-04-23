import 'dart:convert';

/// Parses `GET /auth/me/organizer-certification/quiz` JSON into session + raw
/// question objects. Tolerates wrapped `data`, snake_case keys, and [Map]
/// shapes produced by some JSON decoders.
class OrganizerQuizApiPayload {
  const OrganizerQuizApiPayload({
    required this.session,
    required this.rawQuestions,
  });

  final String session;
  final List<dynamic> rawQuestions;
}

Map<String, dynamic>? decodeJsonObjectFromBody(String? bodyStr) {
  if (bodyStr == null || bodyStr.trim().isEmpty) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(bodyStr);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    return null;
  }
  return null;
}

Map<String, dynamic>? asJsonObject(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

OrganizerQuizApiPayload? parseOrganizerQuizPayload(
  Map<String, dynamic>? json, {
  String? rawBody,
}) {
  Map<String, dynamic>? root = json;
  root ??= decodeJsonObjectFromBody(rawBody);
  if (root == null) {
    return null;
  }

  final Object? data = root['data'];
  if (data is Map) {
    root = Map<String, dynamic>.from(data);
  }

  final String? session = _nonEmptyString(
    root,
    const <String>['quizSession', 'quiz_session'],
  );
  final List<dynamic>? rawQuestions = _nonEmptyQuestionList(root);
  if (session == null || rawQuestions == null) {
    return null;
  }
  return OrganizerQuizApiPayload(session: session, rawQuestions: rawQuestions);
}

String? _nonEmptyString(Map<String, dynamic> map, List<String> keys) {
  for (final String k in keys) {
    final Object? v = map[k];
    if (v is String && v.isNotEmpty) {
      return v;
    }
  }
  return null;
}

List<dynamic>? _nonEmptyQuestionList(Map<String, dynamic> map) {
  for (final String k in const <String>['questions', 'Questions']) {
    final Object? v = map[k];
    if (v is List && v.isNotEmpty) {
      return List<dynamic>.from(v);
    }
  }
  return null;
}
