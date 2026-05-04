import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_category_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/map/report_external_maps.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_severity_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_card_status_badge.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_detail_sheet/report_detail_close_trailing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_detail_sheet/report_detail_evidence_gallery.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_detail_sheet/report_detail_row.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_detail_sheet/report_detail_status_banner.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/file_exists.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

class ReportDetailSheet extends StatefulWidget {
  const ReportDetailSheet({
    super.key,
    required this.report,
    this.onShowSiteOnMap,
    this.onOpenLinkedPollutionSiteDetail,
  });

  final ReportSheetViewModel report;
  final void Function(String siteId)? onShowSiteOnMap;

  /// Opens the linked pollution site after this sheet is popped from the root navigator.
  /// [snapshot] is the row shown in the sheet (used for coordinate fallbacks). Implement in a shell screen.
  final Future<void> Function(String siteId, ReportSheetViewModel snapshot)?
      onOpenLinkedPollutionSiteDetail;

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  bool _isOpeningMap = false;
  bool _isRefreshing = false;
  ReportSheetViewModel? _report;
  StreamSubscription? _realtimeSub;
  RequestCancellationToken? _refreshCancellation;

  ReportSheetViewModel get report => _report ?? widget.report;

  String _formatSubmittedDate(DateTime d) {
    final String locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(d);
  }

  static bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  bool get _hasValidCoordinates =>
      report.latitude != null && report.longitude != null;

  bool get _hasLocationData =>
      (report.address != null && report.address!.trim().isNotEmpty) ||
      _hasValidCoordinates;

  bool get _canOpenExternalMaps =>
      report.status != ReportSheetStatus.approved && _hasValidCoordinates;

  bool get _canOpenInAppMap {
    if (report.siteId == null || report.siteId!.trim().isEmpty) return false;
    return report.status == ReportSheetStatus.approved ||
        report.status == ReportSheetStatus.alreadyReported;
  }

  bool get _canTapLocation => _canOpenExternalMaps || _canOpenInAppMap;

  String get _locationDisplayText {
    final bool hasDistinctAddress =
        report.address != null &&
        report.address!.trim().isNotEmpty &&
        report.address!.trim() != report.title.trim();
    if (hasDistinctAddress) return report.address!;
    if (_hasValidCoordinates) return context.l10n.reportDetailViewOnMap;
    return report.address ?? '';
  }

  void _onLocationTap() {
    if (!_canTapLocation || _isOpeningMap) return;
    if (_canOpenInAppMap) {
      _openInAppSite();
    } else if (_canOpenExternalMaps) {
      _showExternalMapsSheet();
    }
  }

  void _showExternalMapsSheet() {
    AppHaptics.light();
    if (report.latitude == null || report.longitude == null) return;
    unawaited(
      showReportViewLocationDirectionsSheet(
        context: context,
        latitude: report.latitude!,
        longitude: report.longitude!,
      ),
    );
  }

  Future<void> _openInAppSite() async {
    if (report.siteId == null || report.siteId!.trim().isEmpty) return;
    final String siteId = report.siteId!.trim();
    if (widget.onShowSiteOnMap != null) {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onShowSiteOnMap!(siteId);
      return;
    }
    if (widget.onOpenLinkedPollutionSiteDetail != null) {
      if (!mounted) return;
      setState(() => _isOpeningMap = true);
      Navigator.of(context, rootNavigator: true).pop();
      await widget.onOpenLinkedPollutionSiteDetail!(siteId, report);
      return;
    }
    if (!mounted) return;
    if (_hasValidCoordinates) {
      _showExternalMapsSheet();
    } else {
      AppSnack.show(
        context,
        message: context.l10n.reportDetailSiteNotAvailable,
        type: AppSnackType.warning,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _realtimeSub = ServiceLocator.instance.reportsRealtimeService.events.listen(
      (event) {
        final String? reportId = report.reportId;
        if (reportId == null || reportId.isEmpty) return;
        if (event.reportId != reportId) return;
        const Set<String> refreshKinds = <String>{
          'media_appended',
          'status_changed',
          'merged',
          'updated',
        };
        if (!refreshKinds.contains(event.mutationKind)) {
          return;
        }
        _refreshFromBackend();
      },
    );
  }

  @override
  void dispose() {
    _refreshCancellation?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshFromBackend() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshCancellation?.cancel();
    final RequestCancellationToken cancellation = RequestCancellationToken();
    _refreshCancellation = cancellation;
    try {
      final String? reportId = report.reportId;
      if (reportId == null || reportId.isEmpty) return;
      final detail = await ServiceLocator.instance.reportsApiRepository
          .getReportById(reportId, cancellation: cancellation);
      if (!mounted) return;
      setState(() {
        _report = ReportSheetViewModelMapper.fromDetail(detail, context.l10n);
      });
    } on AppError catch (e) {
      if (e.code == 'CANCELLED') return;
      // Best-effort: keep current UI, manual pull-to-refresh exists in list.
    } catch (_) {
      // Best-effort: keep current UI, manual pull-to-refresh exists in list.
    } finally {
      if (identical(_refreshCancellation, cancellation)) {
        _refreshCancellation = null;
      }
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<String> evidencePaths =
        report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage =
        evidencePaths.isNotEmpty &&
        (_isNetworkUrl(evidencePaths.first) ||
            fileExistsSync(evidencePaths.first));
    final ReportDetailStatusBannerData banner =
        reportDetailStatusBannerData(l10n, report);

    return ReportSheetScaffold(
      addBottomInset: false,
      maxHeightFactor: 1.0,
      scrollChromeWithBody: true,
      useModalRouteShape: true,
      animateHandleFadeIn: true,
      titleTextStyle: AppTypography.reportsSheetTitle(textTheme),
      subtitleTextStyle: AppTypography.reportsSheetSubtitle(textTheme),
      subtitleMaxLines: 2,
      title: l10n.reportDetailSheetTitle,
      subtitle: report.reportNumber != null
          ? l10n.reportDetailSheetSubtitleWithNumber(report.reportNumber!)
          : l10n.reportDetailSheetSubtitle,
      trailing: ReportDetailCloseTrailing(
        isRefreshing: _isRefreshing,
        semanticLabel: l10n.semanticClose,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasEvidenceImage) ...<Widget>[
            ReportDetailEvidenceGallery(
              evidencePaths: evidencePaths,
              reportTag: report.reportNumber ?? 'report',
              noPhotosLabel: l10n.reportDetailNoPhotos,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              if (report.reportNumber != null)
                ReportStatePill(
                  label: report.reportNumber!,
                  icon: Icons.tag_rounded,
                  tone: ReportSurfaceTone.neutral,
                ),
              ReportStatusBadge(status: report.status),
              ReportStatePill(
                label: _formatSubmittedDate(report.createdAt),
                icon: Icons.schedule_rounded,
                tone: ReportSurfaceTone.neutral,
              ),
              if (hasEvidenceImage)
                ReportStatePill(
                  label: l10n.reportDetailPhotoAttachedPill,
                  icon: Icons.image_outlined,
                  tone: ReportSurfaceTone.accent,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ReportDetailRow(
            icon: report.category.icon,
            label: l10n.reportReviewCategoryTitle,
            semanticsValue: report.category.localizedTitle(l10n),
            isLast:
                report.severity == null &&
                report.cleanupEffort == null &&
                report.score <= 0 &&
                !_hasLocationData,
            child: Text(
              report.category.localizedTitle(l10n),
              style: AppTypography.reportsRowValue(textTheme),
            ),
          ),
          if (report.severity != null)
            ReportDetailRow(
              icon: Icons.signal_cellular_alt,
              label: l10n.reportReviewSeverityTitle,
              semanticsValue: reportSeverityDisplayLabel(
                l10n,
                report.severity!,
              ),
              isLast:
                  report.cleanupEffort == null &&
                  report.score <= 0 &&
                  !_hasLocationData,
              child: Text(
                reportSeverityDisplayLabel(l10n, report.severity!),
                style: AppTypography.reportsRowValue(textTheme),
              ),
            ),
          if (report.cleanupEffort != null)
            ReportDetailRow(
              icon: Icons.groups_2_outlined,
              label: l10n.reportReviewCleanupEffortTitle,
              semanticsValue: report.cleanupEffort!.label,
              isLast: report.score <= 0 && !_hasLocationData,
              child: Text(
                report.cleanupEffort!.label,
                style: AppTypography.reportsRowValue(textTheme),
              ),
            ),
          if (report.score > 0)
            ReportDetailRow(
              icon: Icons.emoji_events_rounded,
              label: l10n.reportDetailPointsLabel,
              semanticsValue: '+${report.score}',
              isLast: !_hasLocationData,
              child: Text(
                '+${report.score}',
                style: AppTypography.reportsRowValueStrong(textTheme),
              ),
            ),
          if (_hasLocationData)
            ReportDetailRow(
              icon: Icons.location_on_outlined,
              label: l10n.reportReviewLocationTitle,
              semanticsValue: _isOpeningMap
                  ? l10n.reportDetailOpeningInProgress
                  : _locationDisplayText,
              isLast: true,
              onTap: _canTapLocation ? _onLocationTap : null,
              child: _isOpeningMap
                  ? Row(
                      children: <Widget>[
                        SizedBox(
                          width: AppSpacing.iconSm,
                          height: AppSpacing.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.reportDetailOpeningInProgress,
                          style: AppTypography.reportsRowValue(
                            textTheme,
                          ).copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    )
                  : Text(
                      _locationDisplayText,
                      style: AppTypography.reportsRowValue(textTheme),
                    ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            report.title,
            style: AppTypography.reportsSectionHeader(textTheme),
          ),
          if (report.description.trim() != report.title.trim()) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              report.description,
              style:
                  (textTheme.bodyMedium ?? AppTypography.textTheme.bodyMedium!)
                      .copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.divider.withValues(alpha: 0.7), height: 1),
          const SizedBox(height: AppSpacing.lg),
          ReportInfoBanner(
            title: banner.title,
            icon: banner.icon,
            tone: banner.tone,
            message: banner.message,
            titleStyle: AppTypography.reportsBannerTitle(textTheme),
            messageStyle: AppTypography.reportsBannerBody(textTheme),
          ),
        ],
      ),
    );
  }
}
