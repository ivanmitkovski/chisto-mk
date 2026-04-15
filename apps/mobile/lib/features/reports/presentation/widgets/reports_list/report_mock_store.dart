import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_list_item.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

enum ReportStatus {
  underReview(AppColors.accentWarning, Color(0xFFFFF8EC)),
  approved(AppColors.primary, Color(0xFFEDFFF6)),
  declined(AppColors.accentDanger, Color(0xFFFFF0EE)),
  alreadyReported(AppColors.accentInfo, Color(0xFFEDF3FF));

  const ReportStatus(this.color, this.background);
  final Color color;
  final Color background;
}

class MockReport {
  const MockReport({
    this.reportId,
    required this.title,
    required this.description,
    required this.status,
    required this.score,
    required this.category,
    this.reportNumber,
    this.address,
    this.declineReason,
    this.evidenceImagePaths,
    this.cleanupEffort,
    this.severity,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.siteId,
  });

  final String? reportId;
  final String title;
  final String description;
  final String? reportNumber;
  final ReportStatus status;
  final int score;
  final ReportCategory category;
  final String? address;
  final String? declineReason;
  final List<String>? evidenceImagePaths;
  final CleanupEffort? cleanupEffort;
  final int? severity;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? siteId;
}

class ReportsListMockStore {
  const ReportsListMockStore._();

  /// Legacy submissions stored description as `"${category.apiPollutionTypeLabel}: …"`. Category
  /// is shown separately, so strip a matching prefix for display.
  static String _stripCategoryPrefixFromDescription(
    String text,
    ReportCategory category,
  ) {
    final String trimmed = text.trim();
    final String prefix = '${category.apiPollutionTypeLabel}:';
    if (trimmed.length < prefix.length) return trimmed;
    if (!trimmed.toLowerCase().startsWith(prefix.toLowerCase())) {
      return trimmed;
    }
    return trimmed.substring(prefix.length).trimLeft().trim();
  }

  static ReportStatus _statusFromApi(ApiReportStatus s) {
    switch (s) {
      case ApiReportStatus.new_:
      case ApiReportStatus.inReview:
        return ReportStatus.underReview;
      case ApiReportStatus.approved:
        return ReportStatus.approved;
      case ApiReportStatus.deleted:
        return ReportStatus.declined;
    }
  }

  static MockReport fromListItem(ReportListItem r, AppLocalizations l10n) {
    final ReportCategory category = r.category ?? ReportCategory.other;
    final String rawTitle = r.title.trim().isNotEmpty
        ? r.title.trim()
        : l10n.reportSubmittedFallbackCategory;
    final String strippedHeadline =
        _stripCategoryPrefixFromDescription(rawTitle, category);
    final String title =
        strippedHeadline.isNotEmpty ? strippedHeadline : rawTitle;
    final String? optRaw = r.description?.trim();
    final String strippedOpt = optRaw != null && optRaw.isNotEmpty
        ? _stripCategoryPrefixFromDescription(optRaw, category)
        : '';
    final String description =
        strippedOpt.isNotEmpty ? strippedOpt : title;
    final String loc = r.location.trim();
    final bool locationIsDistinct = loc.isNotEmpty &&
        title.isNotEmpty &&
        loc.toLowerCase() != title.toLowerCase();
    return MockReport(
      reportId: r.id,
      title: title,
      description: description,
      status: _statusFromApi(r.status),
      score: r.pointsAwarded,
      category: category,
      reportNumber: r.reportNumber.isNotEmpty ? r.reportNumber : null,
      address: locationIsDistinct ? r.location : null,
      evidenceImagePaths: r.mediaUrls.isNotEmpty ? r.mediaUrls : null,
      cleanupEffort: r.cleanupEffort,
      severity: r.severity,
      createdAt: r.submittedAt,
    );
  }

  static MockReport fromDetail(ReportDetail r, AppLocalizations l10n) {
    final ReportCategory category = r.category ?? ReportCategory.other;
    final String apiTitleRaw = r.title.trim();
    final String strippedHeadline =
        _stripCategoryPrefixFromDescription(apiTitleRaw, category);
    final String title = apiTitleRaw.isNotEmpty
        ? (strippedHeadline.isNotEmpty ? strippedHeadline : apiTitleRaw)
        : l10n.reportSubmittedFallbackCategory;
    final String apiDescriptionRaw = (r.description ?? '').trim();
    final String strippedOpt = apiDescriptionRaw.isNotEmpty
        ? _stripCategoryPrefixFromDescription(apiDescriptionRaw, category)
        : '';
    final String description =
        strippedOpt.isNotEmpty ? strippedOpt : title;

    final String loc = (r.location).trim();
    final bool locationIsDistinct = loc.isNotEmpty &&
        strippedOpt.isNotEmpty &&
        loc.toLowerCase() != strippedOpt.toLowerCase();
    final bool hasValidCoords = ReportGeoFence.contains(
      r.site.latitude,
      r.site.longitude,
    );
    final double? lat = hasValidCoords ? r.site.latitude : null;
    final double? lng = hasValidCoords ? r.site.longitude : null;
    final String? siteId =
        (r.site.id).trim().isNotEmpty ? r.site.id : null;
    final String? placeLabel = r.site.address?.trim().isNotEmpty == true
        ? r.site.address!.trim()
        : (locationIsDistinct ? r.location : null);
    return MockReport(
      reportId: r.id,
      title: title,
      description: description,
      status: _statusFromApi(r.status),
      score: r.pointsAwarded,
      category: category,
      reportNumber: r.reportNumber.isNotEmpty ? r.reportNumber : null,
      address: placeLabel,
      evidenceImagePaths: r.mediaUrls.isNotEmpty ? r.mediaUrls : null,
      cleanupEffort: r.cleanupEffort,
      severity: r.severity,
      createdAt: r.submittedAt,
      latitude: lat,
      longitude: lng,
      siteId: siteId,
    );
  }
}
