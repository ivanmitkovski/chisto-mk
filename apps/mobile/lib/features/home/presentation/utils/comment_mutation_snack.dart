import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_engagement_outcome_snack.dart';
import 'package:flutter/material.dart';

/// Maps comment mutation failures to the same throttled / offline / network UX as site engagement.
void showCommentMutationSnack(
  BuildContext context,
  AppError error, {
  required String fallbackMessage,
}) {
  showSiteEngagementOutcomeSnack(
    context,
    SiteEngagementOutcome.failureWithError(error),
    genericFailureMessage: fallbackMessage,
  );
}
