import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EventFeedbackSnapshot {
  const EventFeedbackSnapshot({
    required this.eventId,
    required this.rating,
    required this.bagsCollected,
    required this.volunteerHours,
    required this.notes,
    required this.createdAt,
  });

  final String eventId;
  final int rating;
  final int bagsCollected;
  final double volunteerHours;
  final String notes;
  final DateTime createdAt;

  double get estimatedKg => bagsCollected * 3.2;
  double get estimatedCo2SavedKg => estimatedKg * 0.7;

  EventFeedbackSnapshot copyWith({
    int? rating,
    int? bagsCollected,
    double? volunteerHours,
    String? notes,
    DateTime? createdAt,
  }) {
    return EventFeedbackSnapshot(
      eventId: eventId,
      rating: rating ?? this.rating,
      bagsCollected: bagsCollected ?? this.bagsCollected,
      volunteerHours: volunteerHours ?? this.volunteerHours,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'rating': rating,
      'bagsCollected': bagsCollected,
      'volunteerHours': volunteerHours,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventFeedbackSnapshot.fromJson(Map<String, dynamic> json) {
    return EventFeedbackSnapshot(
      eventId: json['eventId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt().clamp(1, 5) ?? 5,
      bagsCollected: (json['bagsCollected'] as num?)?.toInt().clamp(0, 100000) ?? 0,
      volunteerHours: ((json['volunteerHours'] as num?)?.toDouble() ?? 1.0).clamp(0.5, 24.0),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class EventFeedbackLocalCache {
  const EventFeedbackLocalCache();

  static const String _key = 'events_feedback_snapshot_v1';

  Future<EventFeedbackSnapshot?> read(String eventId) async {
    final Map<String, dynamic> all = await _readAll();
    final dynamic raw = all[eventId];
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return EventFeedbackSnapshot.fromJson(raw);
  }

  Future<void> write(EventFeedbackSnapshot snapshot) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> all = await _readAll();
    all[snapshot.eventId] = snapshot.toJson();
    await prefs.setString(_key, jsonEncode(all));
  }

  Future<Map<String, dynamic>> _readAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return <String, dynamic>{};
    }
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }
    return decoded;
  }
}
