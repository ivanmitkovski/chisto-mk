import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_reports/src/application/reports_list_session.dart';
import 'package:feature_reports/src/data/outbox/report_draft_repository.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/report_input_sanitizer.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_controller.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_submit_support.dart';
import 'package:feature_reports/src/presentation/l10n/report_category_l10n.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_submitted_dialog.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';

/// Where to go after the post-submit success dialog closes.
sealed class NewReportPostSubmitNavigation {
  const NewReportPostSubmitNavigation._();
}

/// User chose "report another" — caller should reset the wizard draft.
final class NewReportPostSubmitReportAnother
    extends NewReportPostSubmitNavigation {
  const NewReportPostSubmitReportAnother() : super._();
}

/// User finished — caller should [Navigator.pop] with [popResult].
final class NewReportPostSubmitExit extends NewReportPostSubmitNavigation {
  const NewReportPostSubmitExit(this.popResult) : super._();
  final Object? popResult;
}

/// Dependencies for post-submit side effects (injected at the screen boundary).
class NewReportSubmitBindings {
  const NewReportSubmitBindings({
    required this.reportsListSession,
    required this.reportDraftRepository,
  });

  final ReportsListSession reportsListSession;
  final ReportDraftRepository reportDraftRepository;
}

abstract final class NewReportSubmitUiFlow {
  /// Full submit orchestration: persist flush, validate, API/outbox, success dialog, navigation.
  static Future<void> runSubmit({
    required BuildContext context,
    required NewReportController controller,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required NewReportSubmitBindings bindings,
    required VoidCallback onCannotSubmit,
  }) async {
    if (!controller.tryBeginSubmit()) return;

    try {
      await controller.flushPendingPersist(
        titleText: titleController.text,
        descriptionText: descriptionController.text,
      );
      if (!context.mounted) return;
      controller.beginSubmitAttempt();

      if (!controller.canSubmit) {
        controller.resetSubmittingUi();
        onCannotSubmit();
        return;
      }

      final String trimmedTitle = ReportInputSanitizer.clampTitle(
        controller.draft.title,
      );
      final ReportSubmitResult result = await controller.submitReport();
      if (!context.mounted) return;
      bindings.reportsListSession.onSubmitSucceeded(
        result: result,
        title: trimmedTitle,
        draft: controller.draft,
      );
      controller.setSuppressLocalDraftPersist(value: true);
      bumpProfileRefresh();
      controller.markSubmitSentPhase();
      if (context.mounted && MediaQuery.supportsAnnounceOf(context)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || !MediaQuery.supportsAnnounceOf(context)) {
            return;
          }
          SemanticsService.sendAnnouncement(
            View.of(context),
            context.l10n.reportSubmitSentPending,
            Directionality.of(context),
          );
        });
      }
      final NewReportPostSubmitNavigation? nav =
          await NewReportSubmitUiFlow.finishSuccessfulSubmit(
            context: context,
            draft: controller.draft,
            result: result,
            onResetSubmittingUi: () async {
              if (context.mounted) {
                controller.resetSubmittingUi();
              }
            },
          );
      if (context.mounted) {
        _showUploadWarningsIfNeeded(context, result);
      }
      if (!context.mounted || nav == null) {
        return;
      }
      await bindings.reportDraftRepository.clear();
      if (!context.mounted) {
        return;
      }
      switch (nav) {
        case NewReportPostSubmitReportAnother():
          controller.resetDraftAndStartOver();
          titleController.text = '';
          descriptionController.text = '';
        case NewReportPostSubmitExit(:final Object? popResult):
          Navigator.of(context).pop(popResult);
      }
    } on AppError catch (e) {
      if (!context.mounted) return;
      controller.resetSubmittingUi();
      final bool handled = await NewReportSubmitUiFlow.handleSubmitAppError(
        context,
        e,
        controller.loadReportingCapacity,
      );
      if (!context.mounted) return;
      if (!handled) {
        controller.setApiError(e);
      }
    } catch (e) {
      if (!context.mounted) return;
      controller.endSubmitWithError(e);
    }
  }

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
    if (error.code == 'PHONE_NOT_VERIFIED') {
      return handlePhoneNotVerifiedGuardError(context, error);
    }
    if (error.code == 'UNAUTHORIZED' ||
        error.code == 'INVALID_TOKEN_USER' ||
        error.code == 'ACCOUNT_NOT_ACTIVE') {
      AppNavigation.goSignInAndClearStack();
      return true;
    }
    if (error.code == 'REPORTING_COOLDOWN') {
      final ReportCapacity? capacity =
          NewReportSubmitSupport.capacityFromErrorDetails(
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

  static void _showUploadWarningsIfNeeded(
    BuildContext context,
    ReportSubmitResult result,
  ) {
    if (result.uploadPhotosSkippedCount > 0) {
      AppSnack.show(
        context,
        message: context.l10n.reportSubmitPhotosSkippedSnack(
          result.uploadPhotosSkippedCount,
        ),
        type: AppSnackType.warning,
      );
      return;
    }
    if (result.uploadCompressionFallbackCount > 0) {
      AppSnack.show(
        context,
        message: context.l10n.reportSubmitPhotosCompressionWarningSnack(
          result.uploadCompressionFallbackCount,
        ),
        type: AppSnackType.warning,
      );
    }
  }
}
