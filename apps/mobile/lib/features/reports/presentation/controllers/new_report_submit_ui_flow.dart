import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/new_report_submit_support.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_category_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_submitted_dialog.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:flutter/material.dart';

/// Where to go after the post-submit success dialog closes.
sealed class NewReportPostSubmitNavigation {
  const NewReportPostSubmitNavigation._();
}

/// User chose "report another" — caller should reset the wizard draft.
final class NewReportPostSubmitReportAnother extends NewReportPostSubmitNavigation {
  const NewReportPostSubmitReportAnother() : super._();
}

/// User finished — caller should [Navigator.pop] with [popResult].
final class NewReportPostSubmitExit extends NewReportPostSubmitNavigation {
  const NewReportPostSubmitExit(this.popResult) : super._();
  final Object? popResult;
}

abstract final class NewReportSubmitUiFlow {
  /// Shows [ReportSubmittedDialog] and clears submitting UI in [onResetSubmittingUi] (e.g. [setState]).
  ///
  /// Returns `null` if [context] is no longer mounted after the dialog.
  static Future<NewReportPostSubmitNavigation?> finishSuccessfulSubmit({
    required BuildContext context,
    required ReportDraft draft,
    required ReportSubmitResult result,
    required Future<void> Function() onResetSubmittingUi,
  }) async {
    Object? dialogResult;
    try {
      dialogResult = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return ReportSubmittedDialog(
            categoryLabel:
                draft.category?.localizedTitle(ctx.l10n) ??
                ctx.l10n.reportSubmittedFallbackCategory,
            reportNumber: result.reportNumber,
            reportId: result.reportId,
            address: draft.address,
            pointsAwarded: result.pointsAwarded,
            isNewSite: result.isNewSite,
          );
        },
      );
    } finally {
      await onResetSubmittingUi();
    }
    if (!context.mounted) {
      return null;
    }
    if (dialogResult == SubmittedDialogResult.reportAnother) {
      return const NewReportPostSubmitReportAnother();
    }
    return NewReportPostSubmitExit(
      dialogResult is String ? dialogResult : true,
    );
  }

  /// Auth redirect, cooldown dialog, or `false` if the screen should surface [error] as [_apiError].
  static Future<bool> handleSubmitAppError(
    BuildContext context,
    AppError error,
    Future<void> Function() reloadReportingCapacity,
  ) async {
    if (error.code == 'UNAUTHORIZED' ||
        error.code == 'INVALID_TOKEN_USER' ||
        error.code == 'ACCOUNT_NOT_ACTIVE') {
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.signIn,
        (Route<dynamic> route) => false,
      );
      return true;
    }
    if (error.code == 'REPORTING_COOLDOWN') {
      final ReportCapacity? capacity = NewReportSubmitSupport.capacityFromErrorDetails(
        error.details,
        defaultUnlockHint: context.l10n.reportCooldownUnlockHintDefault,
      );
      if (capacity != null) {
        await showReportingCooldownDialog(context, capacity);
        await reloadReportingCapacity();
        return true;
      }
    }
    return false;
  }
}
