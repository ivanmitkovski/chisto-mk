import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/data/sites_api_json_helpers.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/domain/models/co_reporter_profile.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Maps sites API JSON payloads into domain models (feed list, map, detail).
class SitesJsonMapper {
  const SitesJsonMapper();

  SitesListResult sitesListResultFromJson(
    Map<String, dynamic> json, {
    required int page,
    required int limit,
  }) {
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<PollutionSite> sites = data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> m) => siteListItemFromJson(m))
        .toList();
    final Map<String, dynamic>? meta = json['meta'] as Map<String, dynamic>?;
    final int total = (meta?['total'] as num?)?.toInt() ?? sites.length;
    final int pageVal = (meta?['page'] as num?)?.toInt() ?? page;
    final int limitVal = (meta?['limit'] as num?)?.toInt() ?? limit;
    return SitesListResult(
      sites: sites,
      total: total,
      page: pageVal,
      limit: limitVal,
      nextCursor: meta?['nextCursor'] as String?,
    );
  }

  MapSitesResult mapSitesResultFromPayload(
    Map<String, dynamic> json, {
    bool servedFromCache = false,
    DateTime? cachedAt,
    bool isStaleFallback = false,
  }) {
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<PollutionSite> sites = data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> m) => siteListItemFromJson(m))
        .toList();
    DateTime? signedMediaExpiresAt;
    final Object? metaRaw = json['meta'];
    if (metaRaw is Map<String, dynamic>) {
      final String? s = metaRaw['signedMediaExpiresAt'] as String?;
      if (s != null && s.isNotEmpty) {
        signedMediaExpiresAt = DateTime.tryParse(s);
      }
    }
    return MapSitesResult(
      sites: sites,
      servedFromCache: servedFromCache,
      cachedAt: cachedAt,
      isStaleFallback: isStaleFallback,
      signedMediaExpiresAt: signedMediaExpiresAt,
    );
  }

  /// Minimal JSON for disk cache round-trip with [siteListItemFromJson].
  Map<String, dynamic> siteListItemToJson(PollutionSite s) {
    return <String, dynamic>{
      'id': s.id,
      'description': s.description,
      'latestReportTitle': '',
      'latestReportDescription': '',
      'address': null,
      'status': s.statusCode ?? s.statusLabel,
      'pollutionType': s.pollutionType,
      'distanceKm': s.distanceKm,
      'reportCount': 0,
      'upvotesCount': s.score,
      'commentsCount': s.commentsCount,
      'sharesCount': s.shareCount,
      'isUpvotedByMe': s.isUpvotedByMe,
      'isSavedByMe': s.isSavedByMe,
      'latitude': s.latitude,
      'longitude': s.longitude,
      'latestReportMediaUrls': s.mediaUrls,
    };
  }

  PollutionSite siteListItemFromJson(Map<String, dynamic> json) {
    final String desc = json['description'] as String? ?? '';
    final String latestTitle = json['latestReportTitle'] as String? ?? '';
    final String latest = json['latestReportDescription'] as String? ?? '';
    final String? addr = json['address'] as String?;
    final String trimmedAddr = addr?.trim() ?? '';
    final String title = desc.isNotEmpty
        ? desc
        : (normalizeFeedTitle(latestTitle).isNotEmpty
              ? normalizeFeedTitle(latestTitle)
              : (latest.isNotEmpty
                    ? latest
                    : (trimmedAddr.isNotEmpty
                          ? trimmedAddr
                          : 'Pollution site')));
    final double distanceKm = json.containsKey('distanceKm')
        ? ((json['distanceKm'] as num?)?.toDouble() ?? -1)
        : -1;
    final int reportCount = (json['reportCount'] as num?)?.toInt() ?? 0;
    final String statusStr = json['status'] as String? ?? 'REPORTED';
    final String statusCode = statusStr.toUpperCase();
    final (String statusLabel, Color statusColor) = siteStatusToLabelAndColor(
      statusCode,
    );
    final String? pollutionTypeRaw =
        (json['pollutionType'] as String?) ??
        (json['pollution_type'] as String?) ??
        (json['latestReportCategory'] as String?) ??
        (json['category'] as String?);
    final int score =
        (json['upvotesCount'] as num?)?.toInt() ?? reportCount * 5;
    final int commentsCount = (json['commentsCount'] as num?)?.toInt() ?? 0;
    final int sharesCount = (json['sharesCount'] as num?)?.toInt() ?? 0;
    final bool isUpvotedByMe = sitesApiJsonBoolField(
      json,
      'isUpvotedByMe',
      'is_upvoted_by_me',
    );
    final bool isSavedByMe = sitesApiJsonBoolField(
      json,
      'isSavedByMe',
      'is_saved_by_me',
    );
    final double? lat = (json['latitude'] as num?)?.toDouble();
    final double? lng = (json['longitude'] as num?)?.toDouble();
    final List<dynamic> mediaUrlsJson =
        json['latestReportMediaUrls'] as List<dynamic>? ?? <dynamic>[];
    final List<String> imageUrls = mediaUrlsJson
        .whereType<String>()
        .map((String url) => url.trim())
        .where((String url) => url.isNotEmpty)
        .toSet()
        .toList();
    return PollutionSite(
      id: json['id'] as String? ?? '',
      title: title,
      description: desc.isNotEmpty
          ? desc
          : (latestTitle.isNotEmpty && latest.isNotEmpty
                ? latest
                : (latestTitle.isNotEmpty ? latestTitle : latest)),
      statusLabel: statusLabel,
      statusCode: statusCode,
      statusColor: statusColor,
      distanceKm: distanceKm,
      score: score,
      shareCount: sharesCount,
      isUpvotedByMe: isUpvotedByMe,
      isSavedByMe: isSavedByMe,
      participantCount: 0,
      mediaUrls: imageUrls,
      commentsCount: commentsCount,
      firstReport: null,
      coReporterNames: <String>[],
      pollutionType: pollutionTypeRaw == null
          ? null
          : _pollutionTypeLabelFromUnknown(pollutionTypeRaw),
      latitude: lat,
      longitude: lng,
      feedReasons:
          (json['rankingReasons'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      rankingScore: (json['rankingScore'] as num?)?.toDouble(),
      rankingComponents: rankingComponentsFromJson(json['rankingComponents']),
      latestReporterName: json['latestReportReporterName'] as String?,
      latestReporterAvatarUrl: json['latestReportReporterAvatarUrl'] as String?,
      latestReporterUserId: json['latestReportReporterId'] as String?,
      latestReportAt: () {
        final String? s = json['latestReportCreatedAt'] as String?;
        if (s == null || s.isEmpty) return null;
        return DateTime.tryParse(s);
      }(),
    );
  }

  PollutionSite siteDetailFromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> root = sitesApiSiteEntityJsonRoot(json);
    final String desc = root['description'] as String? ?? '';
    final List<dynamic> reportsJson =
        root['reports'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> reports = sitesApiMapListOfObjects(
      reportsJson,
    );
    final List<dynamic> eventsJson =
        root['events'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> events = sitesApiMapListOfObjects(
      eventsJson,
    );

    SiteReport? firstReport;
    String? latestReporterUserId;
    final List<String> orderedUniqueImageUrls = <String>[];
    final Set<String> seenImageUrls = <String>{};
    List<String> aggregatedCoReporterNames = <String>[];
    List<CoReporterProfile> aggregatedCoReporterProfiles =
        <CoReporterProfile>[];

    if (reports.isNotEmpty) {
      final Map<String, dynamic> first = reports.first;
      latestReporterUserId =
          first['reporterId'] as String? ?? first['reporter_id'] as String?;
      for (final Map<String, dynamic> r in reports) {
        final List<dynamic> mediaList = sitesApiReportMediaUrlsList(r);
        for (final dynamic m in mediaList) {
          if (m is String && m.isNotEmpty && seenImageUrls.add(m)) {
            orderedUniqueImageUrls.add(m);
          }
        }
      }
      final List<dynamic> firstMediaList = sitesApiReportMediaUrlsList(first);
      final List<String> firstReportImageUrls = firstMediaList
          .whereType<String>()
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
      final Map<String, dynamic>? reporterJson =
          sitesApiJsonObjectToStringKeyedMap(first['reporter']);
      final String reporterFirstName =
          '${reporterJson?['firstName'] ?? reporterJson?['first_name'] ?? ''}'
              .trim();
      final String reporterLastName =
          '${reporterJson?['lastName'] ?? reporterJson?['last_name'] ?? ''}'
              .trim();
      final String? reporterAvatarUrl =
          reporterJson?['avatarUrl'] as String? ??
          reporterJson?['avatar_url'] as String?;
      final String reporterName = '$reporterFirstName $reporterLastName'.trim();
      final String reportTitle = (first['title'] as String?)?.trim() ?? '';
      final String bodyTrim = (first['description'] as String?)?.trim() ?? '';
      final String resolvedTitle = reportTitle.isNotEmpty
          ? reportTitle
          : (bodyTrim.isNotEmpty ? bodyTrim : 'Site report');
      final String? resolvedBody =
          bodyTrim.isNotEmpty && bodyTrim != resolvedTitle ? bodyTrim : null;
      firstReport = SiteReport(
        id: first['id'] as String? ?? '',
        reporterName: reporterName.isEmpty ? 'Unknown reporter' : reporterName,
        reportedAt:
            DateTime.tryParse(
              first['createdAt'] as String? ??
                  first['created_at'] as String? ??
                  '',
            ) ??
            DateTime.now(),
        title: resolvedTitle,
        description: resolvedBody,
        imageUrls: firstReportImageUrls,
        reporterAvatarUrl: reporterAvatarUrl,
      );
      final Map<
        String,
        ({String name, DateTime? reportedAt, String? avatarUrl})
      >
      coByUserId =
          <String, ({String name, DateTime? reportedAt, String? avatarUrl})>{};
      for (final Map<String, dynamic> r in reports) {
        final List<dynamic> coList = sitesApiReportCoReportersList(r);
        for (final dynamic rawCo in coList) {
          final Map<String, dynamic>? co = sitesApiJsonObjectToStringKeyedMap(
            rawCo,
          );
          if (co == null) continue;
          final String? userId = sitesApiCoReporterRowUserId(co);
          if (userId == null) continue;
          final Map<String, dynamic>? user = sitesApiCoReporterRowUser(co);
          final String name = sitesApiCoReporterDisplayName(user);
          final DateTime? reportedAt = sitesApiCoReporterRowReportedAt(co);
          final Object? avRaw = user?['avatarUrl'] ?? user?['avatar_url'];
          final String? avatarUrl = avRaw is String && avRaw.trim().isNotEmpty
              ? avRaw.trim()
              : null;
          final ({String name, DateTime? reportedAt, String? avatarUrl})?
          existing = coByUserId[userId];
          if (existing == null) {
            coByUserId[userId] = (
              name: name,
              reportedAt: reportedAt,
              avatarUrl: avatarUrl,
            );
          } else {
            final DateTime? p = existing.reportedAt;
            final bool useIncomingTime =
                reportedAt != null && (p == null || reportedAt.isBefore(p));
            final String mergedName = useIncomingTime
                ? sitesApiPreferRicherCoReporterName(name, existing.name)
                : sitesApiPreferRicherCoReporterName(existing.name, name);
            final DateTime? mergedAt = useIncomingTime
                ? reportedAt
                : existing.reportedAt;
            final String? mergedAvatar = useIncomingTime
                ? sitesApiPreferNonEmptyString(avatarUrl, existing.avatarUrl)
                : sitesApiPreferNonEmptyString(existing.avatarUrl, avatarUrl);
            coByUserId[userId] = (
              name: mergedName,
              reportedAt: mergedAt,
              avatarUrl: mergedAvatar,
            );
          }
        }
      }
      final List<
        MapEntry<
          String,
          ({String name, DateTime? reportedAt, String? avatarUrl})
        >
      >
      sortedCo = coByUserId.entries.toList()
        ..sort((
          MapEntry<
            String,
            ({String name, DateTime? reportedAt, String? avatarUrl})
          >
          a,
          MapEntry<
            String,
            ({String name, DateTime? reportedAt, String? avatarUrl})
          >
          b,
        ) {
          final DateTime? ta = a.value.reportedAt;
          final DateTime? tb = b.value.reportedAt;
          if (ta != null && tb != null) return ta.compareTo(tb);
          if (ta != null) return -1;
          if (tb != null) return 1;
          return a.value.name.compareTo(b.value.name);
        });
      aggregatedCoReporterNames = sortedCo
          .map(
            (
              MapEntry<
                String,
                ({String name, DateTime? reportedAt, String? avatarUrl})
              >
              e,
            ) => e.value.name,
          )
          .toList();
      aggregatedCoReporterProfiles = sortedCo
          .map(
            (
              MapEntry<
                String,
                ({String name, DateTime? reportedAt, String? avatarUrl})
              >
              e,
            ) => CoReporterProfile(
              displayName: e.value.name,
              avatarUrl: e.value.avatarUrl,
              userId: e.key,
            ),
          )
          .toList();
    }

    final List<String> fromApiCoReporterNames =
        sitesApiSiteDetailCoReporterNamesFromApiField(
          root['coReporterNames'] ?? root['co_reporter_names'],
        );
    final List<CoReporterProfile> fromApiCoReporterProfiles =
        sitesApiCoReporterSummariesFromApiField(
          root['coReporterSummaries'] ?? root['co_reporter_summaries'],
        );
    final List<CoReporterProfile> coReporterProfiles;
    final List<String> coReporterNames;
    if (fromApiCoReporterProfiles.isNotEmpty) {
      coReporterProfiles = fromApiCoReporterProfiles;
      coReporterNames = fromApiCoReporterNames.isNotEmpty
          ? fromApiCoReporterNames
          : fromApiCoReporterProfiles
                .map((CoReporterProfile p) => p.displayName)
                .toList();
    } else if (aggregatedCoReporterProfiles.isNotEmpty) {
      coReporterProfiles = aggregatedCoReporterProfiles;
      coReporterNames = fromApiCoReporterNames.isNotEmpty
          ? fromApiCoReporterNames
          : aggregatedCoReporterNames;
    } else if (fromApiCoReporterNames.isNotEmpty) {
      coReporterProfiles = fromApiCoReporterNames
          .map((String n) => CoReporterProfile(displayName: n))
          .toList();
      coReporterNames = fromApiCoReporterNames;
    } else {
      coReporterProfiles = <CoReporterProfile>[];
      coReporterNames = <String>[];
    }

    final Map<String, dynamic>? firstReportJson = reports.isNotEmpty
        ? reports.first
        : null;
    final String latestTitle = normalizeFeedTitle(
      firstReportJson?['title'] as String? ?? '',
    );
    final String latestDesc = firstReportJson?['description'] as String? ?? '';
    final String title = desc.isNotEmpty
        ? desc
        : (latestTitle.trim().isNotEmpty
              ? latestTitle.trim()
              : (latestDesc.isNotEmpty ? latestDesc : 'Site'));
    final String statusStr = root['status'] as String? ?? 'REPORTED';
    final String statusCode = statusStr.toUpperCase();
    final (String statusLabel, Color statusColor) = siteStatusToLabelAndColor(
      statusCode,
    );
    final String? pollutionTypeRaw =
        (root['pollutionType'] as String?) ??
        (root['pollution_type'] as String?) ??
        (root['category'] as String?);
    final int reportCount = reports.length;
    final int score =
        (root['upvotesCount'] as num?)?.toInt() ?? reportCount * 5;
    final int commentsCount = (root['commentsCount'] as num?)?.toInt() ?? 0;
    final int sharesCount = (root['sharesCount'] as num?)?.toInt() ?? 0;
    final bool isUpvotedByMe = sitesApiJsonBoolField(
      root,
      'isUpvotedByMe',
      'is_upvoted_by_me',
    );
    final bool isSavedByMe = sitesApiJsonBoolField(
      root,
      'isSavedByMe',
      'is_saved_by_me',
    );

    int totalParticipants = 0;
    final List<CleaningEvent> cleaningEvents = <CleaningEvent>[];
    for (final Map<String, dynamic> ev in events) {
      final int pc =
          ((ev['participantCount'] ?? ev['participant_count']) as num?)
              ?.toInt() ??
          0;
      totalParticipants += pc;
      final String scheduledStr =
          ev['scheduledAt'] as String? ?? ev['scheduled_at'] as String? ?? '';
      final DateTime dateTime =
          DateTime.tryParse(scheduledStr) ?? DateTime.now();
      cleaningEvents.add(
        CleaningEvent(
          id: ev['id'] as String? ?? '',
          title: 'Cleanup event',
          dateTime: dateTime,
          participantCount: pc,
          statusLabel: 'Upcoming',
          statusColor: AppColors.primaryDark,
        ),
      );
    }

    final double? lat = (root['latitude'] as num?)?.toDouble();
    final double? lng = (root['longitude'] as num?)?.toDouble();
    int mergedDuplicateChildCountTotal =
        (root['mergedDuplicateChildCountTotal'] as num?)?.toInt() ??
        (root['merged_duplicate_child_count_total'] as num?)?.toInt() ??
        0;
    if (mergedDuplicateChildCountTotal <= 0) {
      for (final Map<String, dynamic> r in reports) {
        mergedDuplicateChildCountTotal +=
            (r['mergedDuplicateChildCount'] as num?)?.toInt() ??
            (r['merged_duplicate_child_count'] as num?)?.toInt() ??
            0;
      }
    }
    return PollutionSite(
      id: root['id'] as String? ?? '',
      title: title,
      description: desc.isNotEmpty
          ? desc
          : (latestTitle.trim().isNotEmpty && latestDesc.isNotEmpty
                ? latestDesc
                : (latestTitle.trim().isNotEmpty ? latestTitle : latestDesc)),
      statusLabel: statusLabel,
      statusCode: statusCode,
      statusColor: statusColor,
      distanceKm: root.containsKey('distanceKm')
          ? ((root['distanceKm'] as num?)?.toDouble() ?? -1)
          : -1,
      score: score,
      shareCount: sharesCount,
      isUpvotedByMe: isUpvotedByMe,
      isSavedByMe: isSavedByMe,
      participantCount: totalParticipants,
      mediaUrls: orderedUniqueImageUrls,
      commentsCount: commentsCount,
      firstReport: firstReport,
      pollutionType: pollutionTypeRaw == null
          ? null
          : _pollutionTypeLabelFromUnknown(pollutionTypeRaw),
      coReporterNames: coReporterNames,
      coReporterProfiles: coReporterProfiles,
      mergedDuplicateChildCountTotal: mergedDuplicateChildCountTotal,
      cleaningEvents: cleaningEvents,
      latitude: lat,
      longitude: lng,
      feedReasons: const <String>[],
      rankingScore: null,
      rankingComponents: null,
      latestReporterName:
          firstReport != null && firstReport.reporterName != 'Unknown reporter'
          ? firstReport.reporterName
          : null,
      latestReporterAvatarUrl: firstReport?.reporterAvatarUrl,
      latestReportAt: firstReport?.reportedAt,
      latestReporterUserId: latestReporterUserId,
    );
  }

  Map<String, double>? rankingComponentsFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final Map<String, double> map = <String, double>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final Object? val = entry.value;
      if (val is num) {
        map[entry.key] = val.toDouble();
      }
    }
    return map.isEmpty ? null : map;
  }

  String normalizeFeedTitle(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceFirst(RegExp(r'^[A-Za-z ]{2,24}\s*:\s*'), '');
  }

  (String, Color) siteStatusToLabelAndColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return ('Reported', AppColors.accentWarning);
      case 'VERIFIED':
        return ('Verified', AppColors.primary);
      case 'CLEANUP_SCHEDULED':
        return ('Cleanup scheduled', AppColors.accentInfo);
      case 'IN_PROGRESS':
        return ('In progress', AppColors.accentInfo);
      case 'CLEANED':
        return ('Cleaned', AppColors.primary);
      case 'DISPUTED':
        return ('Disputed', AppColors.accentDanger);
      case 'ARCHIVED':
        return ('Archived', AppColors.textMuted);
      default:
        return ('Unknown', AppColors.textMuted);
    }
  }

  SiteMapSearchResponse siteMapSearchResponseFromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
    final List<PollutionSite> items = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(mapSearchItemToPollutionSite)
        .toList();
    final List<dynamic> sugRaw = json['suggestions'] as List<dynamic>? ?? <dynamic>[];
    final List<String> suggestions = sugRaw.whereType<String>().toList();
    final Object? geo = json['geoIntent'];
    SiteMapSearchGeoIntent? geoIntent;
    if (geo is Map<String, dynamic>) {
      geoIntent = SiteMapSearchGeoIntent(
        label: geo['label'] as String? ?? '',
        minLat: (geo['minLat'] as num?)?.toDouble() ?? 0,
        maxLat: (geo['maxLat'] as num?)?.toDouble() ?? 0,
        minLng: (geo['minLng'] as num?)?.toDouble() ?? 0,
        maxLng: (geo['maxLng'] as num?)?.toDouble() ?? 0,
      );
    }
    return SiteMapSearchResponse(
      items: items,
      suggestions: suggestions,
      geoIntent: geoIntent,
    );
  }

  /// One row from `POST /sites/search` `items[]`.
  PollutionSite mapSearchItemToPollutionSite(Map<String, dynamic> json) {
    final String desc = json['description'] as String? ?? '';
    final String? addr = json['address'] as String?;
    final String trimmedAddr = addr?.trim() ?? '';
    final String title = trimmedAddr.isNotEmpty
        ? trimmedAddr
        : (desc.trim().isNotEmpty ? desc.trim() : 'Pollution site');
    final String statusStr = json['status'] as String? ?? 'REPORTED';
    final String statusCode = statusStr.toUpperCase();
    final (String statusLabel, Color statusColor) = siteStatusToLabelAndColor(
      statusCode,
    );
    final double? lat = (json['latitude'] as num?)?.toDouble();
    final double? lng = (json['longitude'] as num?)?.toDouble();
    return PollutionSite(
      id: json['id'] as String? ?? '',
      title: title,
      description: desc,
      statusLabel: statusLabel,
      statusCode: statusCode,
      statusColor: statusColor,
      distanceKm: -1,
      score: 0,
      shareCount: 0,
      isUpvotedByMe: false,
      isSavedByMe: false,
      participantCount: 0,
      mediaUrls: const <String>[],
      commentsCount: 0,
      pollutionType: null,
      latitude: lat,
      longitude: lng,
    );
  }

  String _pollutionTypeLabelFromUnknown(String raw) {
    final ReportCategory? category = ReportCategory.fromApiString(raw);
    if (category != null) {
      return category.apiPollutionTypeLabel;
    }
    final String lower = raw.trim().toLowerCase();
    for (final ReportCategory category in ReportCategory.values) {
      if (category.apiPollutionTypeLabel.toLowerCase() == lower) {
        return category.apiPollutionTypeLabel;
      }
    }
    return ReportCategory.other.apiPollutionTypeLabel;
  }
}
