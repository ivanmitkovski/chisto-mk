import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/site_resolution_helpers.dart';
import 'package:feature_home/src/presentation/widgets/submit_resolution_sheet.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> openMarkSiteAsCleanedFromReport({
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
    if (site != null && hasMyPendingResolution(site)) {
      AppSnack.show(
        context,
        message: context.l10n.submitResolutionAlreadyUnderReviewSnack,
        type: AppSnackType.info,
      );
      return;
    }
    if (site != null && isPollutionSiteResolved(site)) {
      AppSnack.show(
        context,
        message: context.l10n.submitResolutionSiteAlreadyResolvedSnack,
        type: AppSnackType.info,
      );
      return;
    }
    await SubmitResolutionSheet.show(
      context,
      siteId: siteId,
      siteTitle: site?.title ?? snapshot.title,
    );
  } catch (_) {
    if (!context.mounted) return;
    AppSnack.show(
      context,
      message: context.l10n.submitResolutionFailedSnack,
      type: AppSnackType.warning,
    );
  }
}
