import 'package:flutter/material.dart';

import 'cleaning_event.dart';
import 'comment.dart';
import 'site_report.dart';

class PollutionSite {
  const PollutionSite({
    required this.id,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.distanceKm,
    required this.score,
    required this.participantCount,
    required this.imageProvider,
    this.images,
    this.comments = const [],
    this.urgencyLabel,
    this.cleaningEvents = const <CleaningEvent>[],
    this.pollutionType,
    this.firstReport,
    List<String>? coReporterNames,
  }) : coReporterNames = coReporterNames ?? const [];

  final String id;
  final String title;
  final String description;
  final String statusLabel;
  final Color statusColor;
  final double distanceKm;
  final int score;
  final int participantCount;
  final ImageProvider imageProvider;
  final List<ImageProvider>? images;
  final List<Comment> comments;
  final List<CleaningEvent> cleaningEvents;

  /// All images for this site; falls back to the primary image when no list is provided.
  List<ImageProvider> get galleryImages {
    final List<ImageProvider>? imgs = images;
    if (imgs == null || imgs.isEmpty) {
      return <ImageProvider>[imageProvider];
    }
    return imgs;
  }

  /// Number of comments (convenience for UI).
  int get commentCount => comments.length;

  final String? urgencyLabel;
  final String? pollutionType;
  final SiteReport? firstReport;
  final List<String> coReporterNames;
}

