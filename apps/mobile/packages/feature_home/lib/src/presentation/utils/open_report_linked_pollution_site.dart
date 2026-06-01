import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/screens/pollution_site_detail_screen.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches a site by [siteId] and pushes [PollutionSiteDetailScreen], with the same
/// fallbacks previously implemented inside [ReportDetailSheet].
Future<void> openReportLinkedPollutionSiteDetail({
  required BuildContext context,
  required WidgetRef ref,
  required String siteId,
  required ReportSheetViewModel snapshot,
}) async {
  if (!context.mounted) return;
  try {
    final PollutionSite? site = await ref
        .read(sitesRepositoryProvider)
        .getSiteById(siteId);
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
