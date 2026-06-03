import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_draft_summary.dart';
import 'package:feature_reports/src/presentation/navigation/new_report_wizard_pop_result.dart';
import 'package:feature_reports/src/presentation/navigation/reports_navigation.dart';
import 'package:feature_reports/src/presentation/screens/new_report_screen.dart';
import 'package:feature_reports/src/presentation/widgets/draft/draft_choice_sheet.dart'
    show CentralFabDraftChoice, showCentralFabDraftChoiceSheet;
import 'package:feature_reports/src/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:feature_reports/src/presentation/widgets/photo_review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Single entry orchestrator for starting the report wizard from shell chrome.
///
/// **Why**: Central FAB and Reports list FAB must share capacity checks and the
/// three-way draft sheet whenever a resumable SQLite draft exists.
class ReportEntryFlow {
  const ReportEntryFlow._();

  /// `true` if the user may proceed (has credits / emergency or accepted cooldown).
  static Future<bool> ensureReportingAllowed(
    BuildContext context, {
    required WidgetRef ref,
  }) async {
    try {
      final ReportCapacity capacity = await ref
          .read(reportsApiRepositoryProvider)
          .getReportingCapacity();
      if (capacity.creditsAvailable > 0 || capacity.emergencyAvailable) {
        return true;
      }
      if (!context.mounted) {
        return false;
      }
      return showReportingCooldownDialog(context, capacity);
    } on AppError catch (e) {
      if (!context.mounted) {
        return false;
      }
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'ACCOUNT_NOT_ACTIVE') {
        AppNavigation.goSignInAndClearStack();
        return false;
      }
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
      return false;
    } catch (_) {
      if (!context.mounted) {
        return false;
      }
      AppSnack.show(
        context,
        message: context.l10n.homeReportingCapacityCheckFailed,
        type: AppSnackType.warning,
      );
      return false;
    }
  }

  /// When a draft exists, shows the same sheet as the central FAB.
  /// Returns `null` when there is no resumable draft.
  static Future<CentralFabDraftChoice?> promptDraftChoiceIfNeeded({
    required BuildContext context,
    required ReportDraftSummary summary,
  }) async {
    if (!summary.hasDraft) {
      return null;
    }
    return showCentralFabDraftChoiceSheet(context: context, summary: summary);
  }

  /// Camera → review sheet → [NewReportScreen] with initial photo.
  static Future<Object?> openCameraThenNewReport({
    required BuildContext context,
    ImagePicker? imagePickerOverride,
  }) async {
    final ImagePicker picker = imagePickerOverride ?? ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 2048,
      );
    } on PlatformException {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.homeCameraOpenFailed,
          type: AppSnackType.warning,
        );
      }
      return null;
    }

    if (!context.mounted || file == null) {
      return null;
    }
    final XFile selectedFile = file;

    final PhotoReviewResult? result =
        await showModalBottomSheet<PhotoReviewResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.panelBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          builder: (_) => PhotoReviewSheet(file: selectedFile),
        );

    if (!context.mounted) {
      return null;
    }

    if (result == PhotoReviewResult.retake) {
      return openCameraThenNewReport(
        context: context,
        imagePickerOverride: picker,
      );
    } else if (result == PhotoReviewResult.use) {
      return ReportsNavigation.pushNewReportScreen<Object>(
        context,
        initialPhoto: selectedFile,
      );
    }
    return null;
  }

  /// Opens the empty wizard (resume path / list FAB).
  static Future<Object?> openNewReportWizard(
    BuildContext context, {
    String? entryLabel,
    String? entryHint,
  }) {
    return ReportsNavigation.pushNewReportScreen<Object>(
      context,
      entryLabel: entryLabel,
      entryHint: entryHint,
    );
  }

  /// Applies the pop result from [NewReportScreen] after a successful submit.
  static void handleNewReportWizardPopResult(
    Object? result, {
    required void Function(String reportId) onViewSubmittedReport,
    required VoidCallback onViewReportsList,
  }) {
    switch (result) {
      case null:
      case NewReportWizardReportAnother():
        return;
      case NewReportWizardViewReport(:final String reportId):
        onViewSubmittedReport(reportId);
      case NewReportWizardViewReports():
        onViewReportsList();
    }
  }
}
