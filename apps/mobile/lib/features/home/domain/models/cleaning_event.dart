import 'package:flutter/material.dart';

/// Lightweight UI model for a cleaning event associated with a pollution site.
class CleaningEvent {
  const CleaningEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.participantCount,
    this.isOrganizer = false,
    this.isJoined = false,
    this.statusLabel,
    this.statusColor,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final int participantCount;

  /// Whether the current user is an organizer of this event.
  final bool isOrganizer;

  /// Whether the current user has joined as a volunteer.
  final bool isJoined;

  /// Optional status pill (e.g. "Upcoming", "Completed").
  final String? statusLabel;
  final Color? statusColor;
}

