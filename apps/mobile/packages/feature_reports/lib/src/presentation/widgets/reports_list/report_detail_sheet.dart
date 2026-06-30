import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/file_exists.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/data/report_detail_cache.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_event.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_service.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:feature_reports/src/presentation/l10n/cleanup_effort_l10n.dart';
import 'package:feature_reports/src/presentation/l10n/report_category_l10n.dart';
import 'package:feature_reports/src/presentation/l10n/report_severity_l10n.dart';
import 'package:feature_reports/src/presentation/widgets/map/report_external_maps.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_card_status_badge.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet/report_detail_close_trailing.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet/report_detail_evidence_gallery.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet/report_detail_row.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet/report_detail_status_banner.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportDetailSheet extends StatefulWidget {
  const ReportDetailSheet({
    super.key,
    required this.report,
    required this.reportsRealtimeService,
    required this.reportsApiRepository,
    this.reportDetailCache,
    this.isStaleFallback = false,
    this.onShowSiteOnMap,
    this.onOpenLinkedPollutionSiteDetail,
    this.onMarkSiteAsCleaned,
    this.cleanupSectionBuilder,
  });

  final ReportSheetViewModel report;
  final ReportsRealtimeService reportsRealtimeService;
  final ReportsApiRepository reportsApiRepository;
  final ReportDetailCacheStore? reportDetailCache;
  final bool isStaleFallback;
  final void Function(String siteId)? onShowSiteOnMap;

  /// Opens the linked pollution site after this sheet is popped from the root navigator.
  /// [snapshot] is the row shown in the sheet (used for coordinate fallbacks). Implement in a shell screen.
  final Future<void> Function(String siteId, ReportSheetViewModel snapshot)?
  onOpenLinkedPollutionSiteDetail;

  /// Opens cleanup confirmation flow after this sheet is popped from the root navigator.
  final Future<void> Function(String siteId, ReportSheetViewModel snapshot)?
  onMarkSiteAsCleaned;

  /// Optional cleanup submission section (injected from feature_home).
  final Widget Function(
    BuildContext context,
    String siteId,
    ReportSheetViewModel report,
  )?
  cleanupSectionBuilder;

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  bool _isOpeningMap = false;
  bool _isRefreshing = false;
  bool _showStaleBanner = false;
  ReportSheetViewModel? _report;
  StreamSubscription<ReportsOwnerEvent>? _realtimeSub;
  RequestCancellationToken? _refreshCancellation;

  /// Self-heal budget for evidence images that fail to load (e.g. an expired
  /// presigned URL). Each failure re-fetches the report to obtain freshly-signed
  /// URLs; bounded + debounced so a permanently-missing object cannot loop.
  static const int _maxImageErrorRefreshes = 3;
  static const Duration _imageErrorRefreshDebounce = Duration(seconds: 4);
  int _imageErrorRefreshCount = 0;
  DateTime? _lastImageErrorRefreshAt;

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

  bool get _canMarkAsCleaned =>
      report.status == ReportSheetStatus.approved &&
      report.siteId != null &&
      report.siteId!.trim().isNotEmpty &&
      widget.onMarkSiteAsCleaned != null;

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

  Future<void> _markSiteAsCleaned() async {
    if (!_canMarkAsCleaned) return;
    final String siteId = report.siteId!.trim();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await widget.onMarkSiteAsCleaned!(siteId, report);
  }

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _showStaleBanner = widget.isStaleFallback;
    _realtimeSub = widget.reportsRealtimeService.events.listen((event) {
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
    });
  }

  @override
  void dispose() {
    _refreshCancellation?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }

  /// Re-fetches the report when an evidence image fails so the gallery rebuilds
  /// with freshly-signed media URLs. Network sources only; bounded + debounced.
  void _handleEvidenceImageError() {
    if (_isRefreshing) return;
    if (_imageErrorRefreshCount >= _maxImageErrorRefreshes) return;

    final List<String> evidence = report.evidenceImagePaths ?? const <String>[];
    final bool hasNetworkSource = evidence.any(_isNetworkUrl);
    if (!hasNetworkSource) return;

    final DateTime now = DateTime.now();
    final DateTime? last = _lastImageErrorRefreshAt;
    if (last != null && now.difference(last) < _imageErrorRefreshDebounce) {
      return;
    }
    _lastImageErrorRefreshAt = now;
    _imageErrorRefreshCount += 1;
    _refreshFromBackend();
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
      final ReportDetail detail = await widget.reportsApiRepository
          .getReportById(reportId, cancellation: cancellation);
      widget.reportDetailCache?.put(detail);
      if (!mounted) return;
      setState(() {
        _report = ReportSheetViewModelMapper.fromDetail(detail, context.l10n);
        _showStaleBanner = false;
      });
    } on AppError catch (e) {
      if (e.code == 'CANCELLED') return;
      if (mounted) {
        setState(() => _showStaleBanner = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _showStaleBanner = true);
      }
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
    final ReportDetailStatusBannerData banner = reportDetailStatusBannerData(
      l10n,
      report,
    );

    return ReportSheetScaffold(
      addBottomInset: true,
      maxHeightFactor: 1,
      fillAvailableHeight: true,
      useModalRouteShape: true,
      animateHandleFadeIn: true,
      // Single-inset rule: no wrapper padding below the scroll viewport —
      // content scrolls edge-to-edge to the sheet bottom (no clipped strip)
      // and clearance lives inside the scroll content instead (see the
      // SingleChildScrollView padding below + scaffold home-indicator merge).
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      dragHandleSemanticLabel: l10n.semanticClose,
      titleTextStyle: AppTypographySurfaces.reportsSheetTitle(textTheme),
      subtitleTextStyle: AppTypographySurfaces.reportsSheetSubtitle(textTheme),
      title: l10n.reportDetailSheetTitle,
      subtitle: report.reportNumber != null
          ? l10n.reportDetailSheetSubtitleWithNumber(report.reportNumber!)
          : l10n.reportDetailSheetSubtitle,
      trailing: ReportDetailCloseTrailing(
        isRefreshing: _isRefreshing,
        semanticLabel: l10n.semanticClose,
      ),
      child: SingleChildScrollView(
        // The scaffold merges the home-indicator inset on top of this, so the
        // last row keeps the same resting clearance as before the wrapper
        // padding was removed.
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_showStaleBanner) ...<Widget>[
              AppInlineBanner(
                message: l10n.reportDetailStaleBanner,
                tone: AppInlineBannerTone.warning,
                onTap: _isRefreshing ? null : _refreshFromBackend,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (hasEvidenceImage) ...<Widget>[
              ReportDetailEvidenceGallery(
                evidencePaths: evidencePaths,
                reportTag: report.reportNumber ?? 'report',
                noPhotosLabel: l10n.reportDetailNoPhotos,
                onImageError: _handleEvidenceImageError,
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
                style: AppTypographySurfaces.reportsRowValue(textTheme),
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
                  style: AppTypographySurfaces.reportsRowValue(textTheme),
                ),
              ),
            if (report.cleanupEffort != null)
              ReportDetailRow(
                icon: Icons.groups_2_outlined,
                label: l10n.reportReviewCleanupEffortTitle,
                semanticsValue: report.cleanupEffort!.localizedLabel(l10n),
                isLast: report.score <= 0 && !_hasLocationData,
                child: Text(
                  report.cleanupEffort!.localizedLabel(l10n),
                  style: AppTypographySurfaces.reportsRowValue(textTheme),
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
                  style: AppTypographySurfaces.reportsRowValueStrong(textTheme),
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
                          const SizedBox(
                            width: AppSpacing.iconSm,
                            height: AppSpacing.iconSm,
                            child: AppLoadingIndicator(
                              size: AppLoadingIndicatorSize.sm,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.reportDetailOpeningInProgress,
                            style: AppTypographySurfaces.reportsRowValue(
                              textTheme,
                            ).copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      )
                    : Text(
                        _locationDisplayText,
                        style: AppTypographySurfaces.reportsRowValue(textTheme),
                      ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              report.title,
              style: AppTypographySurfaces.reportsSectionHeader(textTheme),
            ),
            if (report.description.trim() != report.title.trim()) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                report.description,
                style:
                    (textTheme.bodyMedium ??
                            AppTypography.textTheme.bodyMedium!)
                        .copyWith(color: AppColors.textSecondary, height: 1.45),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.divider.withValues(alpha: 0.7), height: 1),
            const SizedBox(height: AppSpacing.lg),
            if (widget.cleanupSectionBuilder != null &&
                report.siteId != null &&
                report.siteId!.trim().isNotEmpty)
              widget.cleanupSectionBuilder!(
                context,
                report.siteId!.trim(),
                report,
              )
            else if (_canMarkAsCleaned) ...<Widget>[
              PrimaryButton(
                label: l10n.reportDetailMarkAsCleanedCta,
                onPressed: _markSiteAsCleaned,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ReportInfoBanner(
              title: banner.title,
              icon: banner.icon,
              tone: banner.tone,
              message: banner.message,
              titleStyle: AppTypographySurfaces.reportsBannerTitle(textTheme),
              messageStyle: AppTypographySurfaces.reportsBannerBody(textTheme),
            ),
          ],
        ),
      ),
    );
  }
}
