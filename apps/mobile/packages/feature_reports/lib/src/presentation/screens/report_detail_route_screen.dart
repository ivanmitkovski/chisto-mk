import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/application/reports_providers.dart';
import 'package:feature_reports/src/data/report_detail_cache.dart';
import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';
import 'package:feature_reports/src/presentation/widgets/map/report_external_maps.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_open_resolver.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_detail_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root-stack report detail for notification and deep-link entry.
class ReportDetailRouteScreen extends ConsumerStatefulWidget {
  const ReportDetailRouteScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReportDetailRouteScreen> createState() =>
      _ReportDetailRouteScreenState();
}

class _ReportDetailRouteScreenState extends ConsumerState<ReportDetailRouteScreen> {
  RequestCancellationToken? _cancellation;
  Future<ReportDetailOpenResolution>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _cancellation = RequestCancellationToken();
    _loadFuture = resolveReportDetailForOpen(
      repository: ref.read(reportsApiRepositoryProvider),
      cache: ref.read(reportDetailCacheProvider),
      reportId: widget.reportId,
      cancellation: _cancellation,
    );
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    _cancellation?.cancel();
    _cancellation = RequestCancellationToken();
    setState(() {
      _loadFuture = resolveReportDetailForOpen(
        repository: ref.read(reportsApiRepositoryProvider),
        cache: ref.read(reportDetailCacheProvider),
        reportId: widget.reportId,
        cancellation: _cancellation,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportDetailOpenResolution>(
      future: _loadFuture,
      builder: (BuildContext context, AsyncSnapshot<ReportDetailOpenResolution> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: AppLoadingIndicator()),
          );
        }
        if (snapshot.hasError) {
          final Object err = snapshot.error!;
          final AppError appError =
              err is AppError ? err : AppError.unknown(cause: err);
          return Scaffold(
            body: AppErrorView(error: appError, onRetry: () => unawaited(_retry())),
          );
        }
        final ReportDetailOpenResolution? resolution = snapshot.data;
        if (resolution == null) {
          return Scaffold(
            body: AppErrorView(
              error: AppError.notFound(
                message: context.l10n.notificationsSiteUnavailable,
              ),
              onRetry: () => unawaited(_retry()),
            ),
          );
        }
        return switch (resolution) {
          ReportDetailOpenFresh(:final ReportDetail detail) =>
            _buildDetail(context, detail, isStaleFallback: false),
          ReportDetailOpenStaleFallback(
            :final ReportDetail? detail,
            :final ReportListItem? listItem,
          ) =>
            detail != null
                ? _buildDetail(context, detail, isStaleFallback: true)
                : listItem != null
                    ? _buildFromListItem(context, listItem, isStaleFallback: true)
                    : Scaffold(
                        body: AppEmptyState(
                          icon: Icons.description_outlined,
                          title: context.l10n.notificationsSiteUnavailable,
                          action: AppButton.outlined(
                            label: context.l10n.commonRetry,
                            onPressed: () => unawaited(_retry()),
                          ),
                        ),
                      ),
          ReportDetailOpenBlocked(:final AppError error) => Scaffold(
              body: AppErrorView(error: error, onRetry: () => unawaited(_retry())),
            ),
        };
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    ReportDetail detail, {
    required bool isStaleFallback,
  }) {
    final ReportSheetViewModel display =
        ReportSheetViewModelMapper.fromDetail(detail, context.l10n);
    return _buildSheet(context, display, isStaleFallback: isStaleFallback);
  }

  Widget _buildFromListItem(
    BuildContext context,
    ReportListItem listItem, {
    required bool isStaleFallback,
  }) {
    final ReportSheetViewModel display =
        ReportSheetViewModelMapper.fromListItem(listItem, context.l10n);
    return _buildSheet(context, display, isStaleFallback: isStaleFallback);
  }

  Widget _buildSheet(
    BuildContext context,
    ReportSheetViewModel display, {
    required bool isStaleFallback,
  }) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ReportDetailSheet(
          report: display,
          isStaleFallback: isStaleFallback,
          reportsRealtimeService: ref.read(reportsRealtimeServiceProvider),
          reportsApiRepository: ref.read(reportsApiRepositoryProvider),
          reportDetailCache: ref.read(reportDetailCacheProvider),
          onShowSiteOnMap: AppNavigation.focusMapSite,
          onOpenLinkedPollutionSiteDetail: (String siteId, snapshot) =>
              _openLinkedPollutionSiteDetail(
                context: context,
                ref: ref,
                siteId: siteId,
                snapshot: snapshot,
              ),
        ),
      ),
    );
  }
}

Future<void> _openLinkedPollutionSiteDetail({
  required BuildContext context,
  required WidgetRef ref,
  required String siteId,
  required ReportSheetViewModel snapshot,
}) async {
  if (!context.mounted) return;
  try {
    final bool siteExists = await ref
        .read(sitesRepositoryProvider)
        .getSiteById(siteId)
        .then((site) => site != null);
    if (!context.mounted) return;
    if (!siteExists) {
      if (snapshot.latitude != null && snapshot.longitude != null) {
        AppSnack.show(
          context,
          message: context.l10n.reportDetailSiteNotFoundOpeningMaps,
          type: AppSnackType.warning,
        );
        await showReportViewLocationDirectionsSheet(
          context: context,
          latitude: snapshot.latitude!,
          longitude: snapshot.longitude!,
        );
      } else {
        AppSnack.show(
          context,
          message: context.l10n.reportDetailSiteNotAvailable,
          type: AppSnackType.warning,
        );
      }
      return;
    }
    await AppNavigation.pushSiteDetail(
      SiteDetailByIdRouteArgs(siteId: siteId),
    );
  } on Object {
    if (!context.mounted) return;
    AppSnack.show(
      context,
      message: context.l10n.reportDetailCouldNotLoadSite,
      type: AppSnackType.warning,
    );
    if (snapshot.latitude != null && snapshot.longitude != null) {
      await showReportViewLocationDirectionsSheet(
        context: context,
        latitude: snapshot.latitude!,
        longitude: snapshot.longitude!,
      );
    }
  }
}
