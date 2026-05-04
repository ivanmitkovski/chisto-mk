import 'dart:async';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/new_report_controller.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/resume_draft_banner.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/resume_with_incoming_photo_dialog.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/material.dart';

/// First-frame work: capacity, SQLite restore, optional prune snack, resume banner.
Future<void> runNewReportScreenPostFrameDraftRestore({
  required BuildContext context,
  required NewReportController controller,
  required TextEditingController titleController,
  required TextEditingController descriptionController,
  required bool hasInitialPhoto,
}) async {
  unawaited(controller.loadReportingCapacity());
  ReportDraftLoadResult restoreWork = const ReportDraftLoadResult.empty();

  if (hasInitialPhoto) {
    final ReportDraftSummary peek = await controller.peekSavedDraft();
    if (!context.mounted) {
      return;
    }
    if (peek.hasDraft) {
      final AppLocalizations l10n = context.l10n;
      final ResumeWithIncomingChoice? choice = await showResumeWithIncomingPhotoDialog(
        context: context,
        l10n: l10n,
        summary: peek,
      );
      if (!context.mounted) {
        return;
      }
      if (choice != null) {
        final ReportDraftLoadResult? merged =
            await controller.resolveIncomingPhotoMerge(choice);
        if (merged != null) {
          restoreWork = merged;
        }
      } else {
        await controller.resolveIncomingPhotoMerge(
          ResumeWithIncomingChoice.continueDraft,
        );
      }
    } else {
      await controller.seedInitialPhotoFromPending();
    }
  } else {
    restoreWork = await controller.restoreSavedDraft();
  }

  if (!context.mounted) {
    return;
  }
  final AppLocalizations l10n = context.l10n;
  titleController.text = controller.draft.title;
  descriptionController.text = controller.draft.description;
  if (restoreWork.prunedPhotoCount > 0) {
    AppSnack.show(
      context,
      message: l10n.reportDraftPhotosLost(restoreWork.prunedPhotoCount),
      type: AppSnackType.info,
    );
  }
  if (!hasInitialPhoto &&
      restoreWork.kind == ReportDraftRestoreKind.restored &&
      restoreWork.hasDraft) {
    if (!context.mounted) {
      return;
    }
    final ResumeDraftBannerResult? choice = await showResumeDraftBanner(
      context: context,
      l10n: l10n,
      loadResult: restoreWork,
    );
    if (!context.mounted) {
      return;
    }
    if (choice == ResumeDraftBannerResult.discarded) {
      await controller.discardDraft();
      titleController.text = '';
      descriptionController.text = '';
    }
  }
}
