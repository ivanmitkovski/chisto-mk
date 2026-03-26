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
    this.shareCount = 0,
    this.isUpvotedByMe = false,
    this.isSavedByMe = false,
    required this.participantCount,
    required this.imageProvider,
    this.images,
    this.comments = const [],
    this.commentsCount = 0,
    this.urgencyLabel,
    this.cleaningEvents = const <CleaningEvent>[],
    this.pollutionType,
    this.firstReport,
    List<String>? coReporterNames,
    this.latitude,
    this.longitude,
    this.feedReasons = const <String>[],
    this.rankingScore,
    this.rankingComponents,
  }) : coReporterNames = coReporterNames ?? const [];

  final String id;
  final String title;
  final String description;
  final String statusLabel;
  final Color statusColor;
  final double distanceKm;
  final int score;
  final int shareCount;
  final bool isUpvotedByMe;
  final bool isSavedByMe;
  final int participantCount;
  final ImageProvider imageProvider;
  final List<ImageProvider>? images;
  final List<Comment> comments;
  final int commentsCount;
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
  int get commentCount => comments.isNotEmpty ? comments.length : commentsCount;

  final String? urgencyLabel;
  final String? pollutionType;
  final SiteReport? firstReport;
  final List<String> coReporterNames;
  final double? latitude;
  final double? longitude;
  final List<String> feedReasons;
  final double? rankingScore;
  final Map<String, double>? rankingComponents;

  PollutionSite copyWith({
    String? id,
    String? title,
    String? description,
    String? statusLabel,
    Color? statusColor,
    double? distanceKm,
    int? score,
    int? shareCount,
    bool? isUpvotedByMe,
    bool? isSavedByMe,
    int? participantCount,
    ImageProvider? imageProvider,
    List<ImageProvider>? images,
    List<Comment>? comments,
    int? commentsCount,
    String? urgencyLabel,
    List<CleaningEvent>? cleaningEvents,
    String? pollutionType,
    SiteReport? firstReport,
    List<String>? coReporterNames,
    double? latitude,
    double? longitude,
    List<String>? feedReasons,
    double? rankingScore,
    Map<String, double>? rankingComponents,
  }) {
    return PollutionSite(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      statusLabel: statusLabel ?? this.statusLabel,
      statusColor: statusColor ?? this.statusColor,
      distanceKm: distanceKm ?? this.distanceKm,
      score: score ?? this.score,
      shareCount: shareCount ?? this.shareCount,
      isUpvotedByMe: isUpvotedByMe ?? this.isUpvotedByMe,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      participantCount: participantCount ?? this.participantCount,
      imageProvider: imageProvider ?? this.imageProvider,
      images: images ?? this.images,
      comments: comments ?? this.comments,
      commentsCount: commentsCount ?? this.commentsCount,
      urgencyLabel: urgencyLabel ?? this.urgencyLabel,
      cleaningEvents: cleaningEvents ?? this.cleaningEvents,
      pollutionType: pollutionType ?? this.pollutionType,
      firstReport: firstReport ?? this.firstReport,
      coReporterNames: coReporterNames ?? this.coReporterNames,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      feedReasons: feedReasons ?? this.feedReasons,
      rankingScore: rankingScore ?? this.rankingScore,
      rankingComponents: rankingComponents ?? this.rankingComponents,
    );
  }
}

