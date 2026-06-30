import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_home/src/presentation/providers/site_engagement_provider.dart';
import 'package:flutter/material.dart';

void showSiteEngagementOutcomeSnack(
  BuildContext context,
  SiteEngagementOutcome outcome, {
  String? genericFailureMessage,
}) {
  switch (outcome.kind) {
    case SiteEngagementOutcomeKind.success:
      return;
    case SiteEngagementOutcomeKind.notAuthenticated:
      AppSnack.show(
        context,
        message: context.l10n.siteCardEngagementSignInRequired,
        type: AppSnackType.info,
      );
      return;
    case SiteEngagementOutcomeKind.throttled:
      AppSnack.show(
        context,
        message: context.l10n.siteCardEngagementWaitBriefly,
        type: AppSnackType.info,
      );
      return;
    case SiteEngagementOutcomeKind.queuedOffline:
      AppSnack.show(
        context,
        message: context.l10n.siteEngagementQueuedOfflineSnack,
        type: AppSnackType.info,
      );
      return;
    case SiteEngagementOutcomeKind.failure:
      final AppError? err = outcome.error;
      if (err != null && err.code == 'TOO_MANY_REQUESTS') {
        final Object? details = err.details;
        int? sec;
        if (details is Map<String, dynamic>) {
          final Object? raw = details['retryAfterSeconds'];
          if (raw is int) {
            sec = raw;
          }
        }
        if (sec != null && sec > 0) {
          AppSnack.show(
            context,
            message: context.l10n.siteCardRateLimitedSnack(sec),
            type: AppSnackType.warning,
          );
          return;
        }
      }
      if (err != null) {
        AppSnack.failure(context, error: err);
        return;
      }
      AppSnack.show(
        context,
        message:
            genericFailureMessage ?? context.l10n.siteCardUpvoteFailedSnack,
        type: AppSnackType.warning,
      );
      return;
  }
}
