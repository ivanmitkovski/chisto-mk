import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

const ImageProvider _placeholderImage =
    AssetImage('assets/images/content/people_cleaning.png');

class ApiSitesRepository implements SitesRepository {
  ApiSitesRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<SitesListResult> getSites({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final List<String> queryParams = <String>['page=$page', 'limit=$limit'];
    if (latitude != null) queryParams.add('lat=$latitude');
    if (longitude != null) queryParams.add('lng=$longitude');
    queryParams.add('radiusKm=$radiusKm');
    if (status != null && status.isNotEmpty) queryParams.add('status=$status');
    final String path = '/sites?${queryParams.join('&')}';

    final ApiResponse response = await _client.get(path);
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();

    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final List<PollutionSite> sites = data
        .whereType<Map<String, dynamic>>()
        .map<PollutionSite>(_siteListItemFromJson)
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
    );
  }

  @override
  Future<PollutionSite?> getSiteById(String id) async {
    try {
      final ApiResponse response = await _client.get('/sites/$id');
      final Map<String, dynamic>? json = response.json;
      if (json == null) return null;
      return _siteDetailFromJson(json);
    } on AppError catch (e) {
      if (e.code == 'NOT_FOUND' || e.code == 'SITE_NOT_FOUND') return null;
      rethrow;
    }
  }

  PollutionSite _siteListItemFromJson(Map<String, dynamic> json) {
    final String desc = json['description'] as String? ?? '';
    final String latestTitle = json['latestReportTitle'] as String? ?? '';
    final String latest = json['latestReportDescription'] as String? ?? '';
    final String title = desc.isNotEmpty
        ? desc
        : (latestTitle.isNotEmpty
            ? latestTitle
            : (latest.isNotEmpty ? latest : 'Pollution site'));
    final double distanceKm = (json['distanceKm'] as num?)?.toDouble() ?? 0;
    final int reportCount = (json['reportCount'] as num?)?.toInt() ?? 0;
    final String statusStr = json['status'] as String? ?? 'REPORTED';
    final (String statusLabel, Color statusColor) = _siteStatusToLabelAndColor(statusStr);
    final int score = reportCount * 5;
    final double? lat = (json['latitude'] as num?)?.toDouble();
    final double? lng = (json['longitude'] as num?)?.toDouble();
    final List<dynamic> mediaUrlsJson = json['latestReportMediaUrls'] as List<dynamic>? ?? <dynamic>[];
    final String? firstImageUrl = mediaUrlsJson.isNotEmpty && mediaUrlsJson.first is String
        ? mediaUrlsJson.first as String
        : null;
    final ImageProvider imageProvider = firstImageUrl != null
        ? NetworkImage(firstImageUrl)
        : _placeholderImage;
    return PollutionSite(
      id: json['id'] as String? ?? '',
      title: title,
      description: desc.isNotEmpty
          ? desc
          : (latestTitle.isNotEmpty && latest.isNotEmpty
              ? latest
              : (latestTitle.isNotEmpty ? latestTitle : latest)),
      statusLabel: statusLabel,
      statusColor: statusColor,
      distanceKm: distanceKm,
      score: score,
      participantCount: 0,
      imageProvider: imageProvider,
      images: firstImageUrl != null ? <ImageProvider>[NetworkImage(firstImageUrl)] : null,
      firstReport: null,
      coReporterNames: <String>[],
      latitude: lat,
      longitude: lng,
    );
  }

  PollutionSite _siteDetailFromJson(Map<String, dynamic> json) {
    final String desc = json['description'] as String? ?? '';
    final List<dynamic> reportsJson = json['reports'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> reports =
        reportsJson.whereType<Map<String, dynamic>>().toList();
    final List<dynamic> eventsJson = json['events'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> events =
        eventsJson.whereType<Map<String, dynamic>>().toList();

    SiteReport? firstReport;
    final List<ImageProvider> imageProviders = <ImageProvider>[];
    List<String> coReporterNames = <String>[];

    if (reports.isNotEmpty) {
      final Map<String, dynamic> first = reports.first;
      for (final Map<String, dynamic> r in reports) {
        final List<dynamic> mediaList = r['mediaUrls'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic m in mediaList) {
          if (m is String && m.isNotEmpty) {
            imageProviders.add(NetworkImage(m));
          }
        }
      }
      final List<dynamic> firstMediaList = first['mediaUrls'] as List<dynamic>? ?? <dynamic>[];
      final List<ImageProvider> firstReportImages = firstMediaList
          .whereType<String>()
          .map<ImageProvider>((String u) => NetworkImage(u))
          .toList();
      final String reporterFirstName =
          (first['reporter'] as Map<String, dynamic>?)?['firstName'] as String? ?? '';
      final String reporterLastName =
          (first['reporter'] as Map<String, dynamic>?)?['lastName'] as String? ?? '';
      final String reporterName = '$reporterFirstName $reporterLastName'.trim();
      final String reportTitle = (first['title'] as String?)?.trim() ?? '';
      final String bodyTrim = (first['description'] as String?)?.trim() ?? '';
      final String resolvedTitle = reportTitle.isNotEmpty
          ? reportTitle
          : (bodyTrim.isNotEmpty ? bodyTrim : 'Report');
      final String? resolvedBody =
          bodyTrim.isNotEmpty && bodyTrim != resolvedTitle ? bodyTrim : null;
      firstReport = SiteReport(
        id: first['id'] as String? ?? '',
        reporterName: reporterName.isEmpty ? 'Anonymous' : reporterName,
        reportedAt: DateTime.tryParse(first['createdAt'] as String? ?? '') ?? DateTime.now(),
        title: resolvedTitle,
        description: resolvedBody,
        images: firstReportImages,
      );
      final List<dynamic> coList = first['coReporters'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic co in coList) {
        if (co is Map<String, dynamic>) {
          final Map<String, dynamic>? user = co['user'] as Map<String, dynamic>?;
          if (user != null) {
            final String fn = user['firstName'] as String? ?? '';
            final String ln = user['lastName'] as String? ?? '';
            final String name = '$fn $ln'.trim();
            if (name.isNotEmpty) coReporterNames.add(name);
          }
        }
      }
    }

    final Map<String, dynamic>? firstReportJson =
        reports.isNotEmpty ? reports.first : null;
    final String latestTitle = firstReportJson?['title'] as String? ?? '';
    final String latestDesc = firstReportJson?['description'] as String? ?? '';
    final String title = desc.isNotEmpty
        ? desc
        : (latestTitle.trim().isNotEmpty
            ? latestTitle.trim()
            : (latestDesc.isNotEmpty ? latestDesc : 'Pollution site'));
    final String statusStr = json['status'] as String? ?? 'REPORTED';
    final (String statusLabel, Color statusColor) = _siteStatusToLabelAndColor(statusStr);
    final int reportCount = reports.length;
    final int score = reportCount * 5;

    int totalParticipants = 0;
    final List<CleaningEvent> cleaningEvents = <CleaningEvent>[];
    for (final Map<String, dynamic> ev in events) {
      final int pc = (ev['participantCount'] as num?)?.toInt() ?? 0;
      totalParticipants += pc;
      final String scheduledStr = ev['scheduledAt'] as String? ?? '';
      final DateTime dateTime = DateTime.tryParse(scheduledStr) ?? DateTime.now();
      cleaningEvents.add(CleaningEvent(
        id: ev['id'] as String? ?? '',
        title: 'Cleanup event',
        dateTime: dateTime,
        participantCount: pc,
        statusLabel: 'Upcoming',
        statusColor: AppColors.primaryDark,
      ));
    }

    final ImageProvider imageProvider = imageProviders.isNotEmpty
        ? imageProviders.first
        : _placeholderImage;

    final double? lat = (json['latitude'] as num?)?.toDouble();
    final double? lng = (json['longitude'] as num?)?.toDouble();
    return PollutionSite(
      id: json['id'] as String? ?? '',
      title: title,
      description: desc.isNotEmpty
          ? desc
          : (latestTitle.trim().isNotEmpty && latestDesc.isNotEmpty
              ? latestDesc
              : (latestTitle.trim().isNotEmpty ? latestTitle : latestDesc)),
      statusLabel: statusLabel,
      statusColor: statusColor,
      distanceKm: 0,
      score: score,
      participantCount: totalParticipants,
      imageProvider: imageProvider,
      images: imageProviders.isNotEmpty ? imageProviders : null,
      firstReport: firstReport,
      coReporterNames: coReporterNames,
      cleaningEvents: cleaningEvents,
      latitude: lat,
      longitude: lng,
    );
  }

  (String, Color) _siteStatusToLabelAndColor(String status) {
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
      default:
        return ('Reported', AppColors.accentWarning);
    }
  }
}
