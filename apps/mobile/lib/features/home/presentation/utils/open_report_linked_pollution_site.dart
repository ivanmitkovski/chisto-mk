import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/map/report_external_maps.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Fetches a site by [siteId] and pushes [PollutionSiteDetailScreen], with the same
/// fallbacks previously implemented inside [ReportDetailSheet].
Future<void> openReportLinkedPollutionSiteDetail({
  required BuildContext context,
  required String siteId,
  required ReportSheetViewModel snapshot,
}) async {
  if (!context.mounted) return;
  try {
    final PollutionSite? site =
        await ServiceLocator.instance.sitesRepository.getSiteById(siteId);
    if (!context.mounted) return;
    if (site == null) {
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
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(site: site),
      ),
    );
  } catch (_) {
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
