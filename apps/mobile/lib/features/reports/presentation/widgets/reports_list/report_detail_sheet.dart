import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/cache/report_image_provider.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/directions_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_mock_store.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_card.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/device_platform.dart';
import 'package:chisto_mobile/shared/utils/file_exists.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';

const List<String> _severityLabels = <String>[
  'Low',
  'Moderate',
  'Significant',
  'High',
  'Critical',
];

String _severityLabel(int value) =>
    '${value.clamp(1, 5)} – ${_severityLabels[(value.clamp(1, 5) - 1)]}';

class ReportDetailSheet extends StatefulWidget {
  const ReportDetailSheet({super.key, required this.report});

  final MockReport report;

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  bool _isOpeningMap = false;
  bool _isRefreshing = false;
  MockReport? _report;
  StreamSubscription? _realtimeSub;

  MockReport get report => _report ?? widget.report;

  static String _formatDateFull(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  bool get _hasValidCoordinates =>
      report.latitude != null &&
      report.longitude != null;

  bool get _hasLocationData =>
      (report.address != null && report.address!.trim().isNotEmpty) ||
      _hasValidCoordinates;

  bool get _canOpenExternalMaps =>
      report.status != ReportStatus.approved && _hasValidCoordinates;

  bool get _canOpenInAppMap {
    if (report.siteId == null || report.siteId!.trim().isEmpty) return false;
    return report.status == ReportStatus.approved ||
        report.status == ReportStatus.alreadyReported;
  }

  bool get _canTapLocation => _canOpenExternalMaps || _canOpenInAppMap;

  String get _locationDisplayText {
    final bool hasDistinctAddress = report.address != null &&
        report.address!.trim().isNotEmpty &&
        report.address!.trim() != report.title.trim();
    if (hasDistinctAddress) return report.address!;
    if (_hasValidCoordinates) return 'View on map';
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext sheetContext) {
        return DirectionsSheet(
          mode: DirectionsSheetMode.viewLocation,
          onAppleMapsTap: () {
            Navigator.of(sheetContext).pop();
            _launchExternalMap(useAppleMaps: true);
          },
          onGoogleMapsTap: () {
            Navigator.of(sheetContext).pop();
            _launchExternalMap(useAppleMaps: false);
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  Future<void> _launchExternalMap({required bool useAppleMaps}) async {
    if (report.latitude == null || report.longitude == null) return;
    final String destStr = '${report.latitude},${report.longitude}';
    final Uri url = useAppleMaps && DevicePlatform.isIOS
        ? Uri.parse('https://maps.apple.com/?ll=$destStr')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$destStr',
          );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        AppSnack.show(
          context,
          message: 'Could not open Maps',
          type: AppSnackType.warning,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: 'Could not open Maps',
          type: AppSnackType.warning,
        );
      }
    }
  }

  Future<void> _openInAppSite() async {
    if (report.siteId == null || report.siteId!.trim().isEmpty) return;
    setState(() => _isOpeningMap = true);
    try {
      final PollutionSite? site = await ServiceLocator.instance.sitesRepository
          .getSiteById(report.siteId!);
      if (!mounted) return;
      setState(() => _isOpeningMap = false);
      if (site == null) {
        if (_hasValidCoordinates) {
          AppSnack.show(
            context,
            message: 'Site not found. Opening in maps.',
            type: AppSnackType.warning,
          );
          _showExternalMapsSheet();
        } else {
          AppSnack.show(
            context,
            message: 'Site not available.',
            type: AppSnackType.warning,
          );
        }
        return;
      }
      final NavigatorState navigator = Navigator.of(context);
      navigator.pop();
      await navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PollutionSiteDetailScreen(site: site),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOpeningMap = false);
      AppSnack.show(
        context,
        message: 'Could not load site.',
        type: AppSnackType.warning,
      );
      if (_hasValidCoordinates) {
        _showExternalMapsSheet();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    ServiceLocator.instance.reportsRealtimeService.start();
    _realtimeSub = ServiceLocator.instance.reportsRealtimeService.events.listen((event) {
      final String? reportId = report.reportId;
      if (reportId == null || reportId.isEmpty) return;
      if (event.reportId != reportId) return;
      _refreshFromBackend();
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshFromBackend() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final String? reportId = report.reportId;
      if (reportId == null || reportId.isEmpty) return;
      final detail = await ServiceLocator.instance.reportsApiRepository.getReportById(reportId);
      if (!mounted) return;
      setState(() {
        _report = ReportsListMockStore.fromDetail(detail);
      });
    } catch (_) {
      // Best-effort: keep current UI, manual pull-to-refresh exists in list.
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> evidencePaths = report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage = evidencePaths.isNotEmpty &&
        (_isNetworkUrl(evidencePaths.first) ||
            fileExistsSync(evidencePaths.first));

    return ReportSheetScaffold(
      addBottomInset: false,
      title: 'Report details',
      subtitle: report.reportNumber != null
          ? '${report.reportNumber} · See what you submitted and how moderators handled this report.'
          : 'See what you submitted and how moderators handled this report.',
      trailing: ReportCircleIconButton(
        icon: _isRefreshing ? Icons.sync_rounded : Icons.close_rounded,
        semanticLabel: 'Close',
        onTap: () {
          AppHaptics.tap();
          Navigator.of(context).pop();
        },
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (hasEvidenceImage) ...<Widget>[
              _ReportEvidenceGallery(
                evidencePaths: evidencePaths,
                reportTag: report.reportNumber ?? 'report',
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
                  label: _formatDateFull(report.createdAt),
                  icon: Icons.schedule_rounded,
                  tone: ReportSurfaceTone.neutral,
                ),
                if (hasEvidenceImage)
                  const ReportStatePill(
                    label: 'Photo attached',
                    icon: Icons.image_outlined,
                    tone: ReportSurfaceTone.accent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: report.category.icon,
              label: 'Category',
              isLast: report.severity == null &&
                  report.cleanupEffort == null &&
                  report.score <= 0 &&
                  !_hasLocationData,
              child: Text(
                report.category.label,
                style: AppTypography.cardTitle,
              ),
            ),
            if (report.severity != null)
              _DetailRow(
                icon: Icons.signal_cellular_alt,
                label: 'Severity',
                isLast: report.cleanupEffort == null &&
                    report.score <= 0 &&
                    !_hasLocationData,
                child: Text(
                  _severityLabel(report.severity!),
                  style: AppTypography.cardTitle,
                ),
              ),
            if (report.cleanupEffort != null)
              _DetailRow(
                icon: Icons.groups_2_outlined,
                label: 'Cleanup effort',
                isLast: report.score <= 0 && !_hasLocationData,
                child: Text(
                  report.cleanupEffort!.label,
                  style: AppTypography.cardTitle,
                ),
              ),
            if (report.score > 0)
              _DetailRow(
                icon: Icons.emoji_events_rounded,
                label: 'Points',
                isLast: !_hasLocationData,
                child: Text(
                  '+${report.score}',
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentWarning,
                  ),
                ),
              ),
            if (_hasLocationData)
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                isLast: true,
                onTap: _canTapLocation ? _onLocationTap : null,
                child: _isOpeningMap
                    ? Row(
                        children: <Widget>[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Opening…',
                            style: AppTypography.textTheme.bodyMedium!.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _locationDisplayText,
                        style: AppTypography.textTheme.bodyMedium!.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              report.title,
              style: AppTypography.sectionHeader,
            ),
            if (report.description.trim() != report.title.trim()) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                report.description,
                style: AppTypography.textTheme.bodyMedium!.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.divider.withValues(alpha: 0.7), height: 1),
            const SizedBox(height: AppSpacing.lg),
            ReportInfoBanner(
              title: report.status == ReportStatus.underReview
                  ? 'Under review by moderators'
                  : report.status == ReportStatus.approved
                      ? 'Approved and linked to a site'
                      : report.status == ReportStatus.alreadyReported
                          ? 'Already tracked as an existing site'
                          : 'Review outcome',
              icon: report.status == ReportStatus.approved
                  ? Icons.verified_outlined
                  : report.status == ReportStatus.declined
                      ? Icons.info_outline_rounded
                      : Icons.schedule_rounded,
              tone: report.status == ReportStatus.approved
                  ? ReportSurfaceTone.success
                  : report.status == ReportStatus.declined
                      ? ReportSurfaceTone.danger
                      : report.status == ReportStatus.alreadyReported
                          ? ReportSurfaceTone.warning
                          : ReportSurfaceTone.neutral,
              message: report.status == ReportStatus.underReview
                  ? 'Moderators are checking your evidence and location before they decide how to handle this report.'
                  : report.status == ReportStatus.approved
                      ? 'This report helped confirm a public pollution site and may contribute to cleanup actions.'
                      : report.status == ReportStatus.alreadyReported
                          ? 'Your report matched an existing site. The evidence is still useful for understanding the problem.'
                          : report.declineReason ??
                              'This report could not be approved in its current form.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportEvidenceGallery extends StatelessWidget {
  const _ReportEvidenceGallery({
    required this.evidencePaths,
    required this.reportTag,
  });

  final List<String> evidencePaths;
  final String reportTag;

  static bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static List<String> _validPaths(List<String> paths) {
    return paths.where((String path) {
      if (_isNetworkUrl(path)) return true;
      return fileExistsSync(path);
    }).toList();
  }

  ImageProvider _imageForPath(String path) =>
      imageProviderForReportEvidence(path);

  @override
  Widget build(BuildContext context) {
    final List<String> validPaths = _validPaths(evidencePaths);
    if (validPaths.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radius22),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 32,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No photos',
                  style: AppTypography.textTheme.bodySmall!.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<GalleryImageItem> items = List<GalleryImageItem>.generate(
      validPaths.length,
      (int index) => GalleryImageItem(
        image: _imageForPath(validPaths[index]),
        heroTag: 'report-evidence-$reportTag-$index',
        semanticLabel: 'Evidence photo ${index + 1}',
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius22),
      child: ImmersivePhotoGallery(
        items: items,
        aspectRatio: 16 / 9,
        borderRadius: 0,
        openLabel: 'Open report evidence photos',
        bottomCenterBuilder:
            (BuildContext context, int currentIndex, int totalCount) {
          return GalleryGlassPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.photo_library_outlined,
                  size: 13,
                  color: AppColors.textOnDark,
                ),
                const SizedBox(width: 6),
                Text(
                  totalCount > 1 ? 'Tap to expand' : 'Open photo',
                  style: AppTypography.chipLabel.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
    this.isLast = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: AppSpacing.iconMd, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AppTypography.cardSubtitle,
          ),
        ),
        Expanded(child: child),
        if (onTap != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Icon(
              Icons.chevron_right_rounded,
              size: AppSpacing.iconMd,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
    if (onTap != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: row,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: row,
    );
  }
}
