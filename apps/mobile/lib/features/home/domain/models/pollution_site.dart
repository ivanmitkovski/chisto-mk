import 'package:flutter/material.dart';

import 'cleaning_event.dart';
import 'co_reporter_profile.dart';
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
    this.primaryImageUrl,
    this.images,
    this.comments = const [],
    this.commentsCount = 0,
    this.urgencyLabel,
    this.cleaningEvents = const <CleaningEvent>[],
    this.pollutionType,
    this.firstReport,
    List<String>? coReporterNames,
    List<CoReporterProfile>? coReporterProfiles,
    this.mergedDuplicateChildCountTotal = 0,
    this.latitude,
    this.longitude,
    this.feedReasons = const <String>[],
    this.rankingScore,
    this.rankingComponents,
    this.latestReporterName,
    this.latestReporterAvatarUrl,
    this.latestReportAt,
    this.latestReporterUserId,
  }) : coReporterNames = coReporterNames ?? const [],
       coReporterProfiles = coReporterProfiles ?? const [];

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

  /// First remote (or local file) media URL when known; used for map pin thumbnails.
  final String? primaryImageUrl;

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

  final String? urgencyLabel;
  final String? pollutionType;
  final SiteReport? firstReport;
  final List<String> coReporterNames;

  /// Richer co-reporter rows when the API returns avatars (GET /sites/:id `coReporterSummaries`).
  final List<CoReporterProfile> coReporterProfiles;

  /// Duplicate child reports merged into site reports (same or other reporters); from GET /sites/:id.
  final int mergedDuplicateChildCountTotal;

  final double? latitude;
  final double? longitude;
  final List<String> feedReasons;
  final double? rankingScore;
  final Map<String, double>? rankingComponents;

  /// Latest report author (feed list API).
  final String? latestReporterName;
  final String? latestReporterAvatarUrl;
  final DateTime? latestReportAt;

  /// When non-null, matches [User.id] of [latestReporterName] (feed: `latestReportReporterId`).
  final String? latestReporterUserId;

  /// Number of comments (convenience for UI).
  int get commentCount => comments.isNotEmpty ? comments.length : commentsCount;

  /// Stats chip (groups icon): co-reporter count, or merged duplicate count when there are no other reporters.
  int get siteParticipantStatsBadgeValue =>
      coReporterNames.isNotEmpty ? coReporterNames.length : mergedDuplicateChildCountTotal;

  /// Modal / list: prefer [coReporterProfiles] when it carries avatars; otherwise fall back to [coReporterNames].
  List<CoReporterProfile> get displayCoReporterProfiles {
    if (coReporterProfiles.isNotEmpty) {
      return coReporterProfiles;
    }
    return coReporterNames
        .map((String n) => CoReporterProfile(displayName: n))
        .toList();
  }

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
    String? primaryImageUrl,
    List<ImageProvider>? images,
    List<Comment>? comments,
    int? commentsCount,
    String? urgencyLabel,
    List<CleaningEvent>? cleaningEvents,
    String? pollutionType,
    SiteReport? firstReport,
    List<String>? coReporterNames,
    List<CoReporterProfile>? coReporterProfiles,
    int? mergedDuplicateChildCountTotal,
    double? latitude,
    double? longitude,
    List<String>? feedReasons,
    double? rankingScore,
    Map<String, double>? rankingComponents,
    String? latestReporterName,
    String? latestReporterAvatarUrl,
    DateTime? latestReportAt,
    String? latestReporterUserId,
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
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      images: images ?? this.images,
      comments: comments ?? this.comments,
      commentsCount: commentsCount ?? this.commentsCount,
      urgencyLabel: urgencyLabel ?? this.urgencyLabel,
      cleaningEvents: cleaningEvents ?? this.cleaningEvents,
      pollutionType: pollutionType ?? this.pollutionType,
      firstReport: firstReport ?? this.firstReport,
      coReporterNames: coReporterNames ?? this.coReporterNames,
      coReporterProfiles: coReporterProfiles ?? this.coReporterProfiles,
      mergedDuplicateChildCountTotal:
          mergedDuplicateChildCountTotal ?? this.mergedDuplicateChildCountTotal,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      feedReasons: feedReasons ?? this.feedReasons,
      rankingScore: rankingScore ?? this.rankingScore,
      rankingComponents: rankingComponents ?? this.rankingComponents,
      latestReporterName: latestReporterName ?? this.latestReporterName,
      latestReporterAvatarUrl:
          latestReporterAvatarUrl ?? this.latestReporterAvatarUrl,
      latestReportAt: latestReportAt ?? this.latestReportAt,
      latestReporterUserId:
          latestReporterUserId ?? this.latestReporterUserId,
    );
  }
}

