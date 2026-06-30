import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/data/report_upload_image_validator.dart';
import 'package:feature_reports/src/domain/report_field_limits.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_controller.dart';
import 'package:feature_reports/src/presentation/widgets/photo_review_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/photo_source_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

Future<void> runNewReportScreenAddPhoto({
  required BuildContext context,
  required NewReportController controller,
  required ImagePicker imagePicker,
  required VoidCallback scheduleDraftSave,
}) async {
  if (controller.draft.photos.length >= ReportFieldLimits.maxPhotos ||
      controller.isProcessingPhotoFlow) {
    return;
  }

  final ImageSource? source = await showPhotoSourceModal(context);
  if (source == null || !context.mounted) return;
  await runNewReportScreenPickAndReview(
    context: context,
    controller: controller,
    imagePicker: imagePicker,
    source: source,
    scheduleDraftSave: scheduleDraftSave,
  );
}

Future<void> runNewReportScreenPickAndReview({
  required BuildContext context,
  required NewReportController controller,
  required ImagePicker imagePicker,
  required ImageSource source,
  required VoidCallback scheduleDraftSave,
}) async {
  if (controller.isProcessingPhotoFlow) return;

  controller.setProcessingPhotoFlow(value: true);

  try {
    while (context.mounted) {
      XFile? file;
      try {
        file = await imagePicker.pickImage(
          source: source,
          preferredCameraDevice: CameraDevice.rear,
        );
      } on PlatformException {
        if (context.mounted) {
          AppSnack.show(
            context,
            message: context.l10n.reportFlowCameraUnavailableSnack,
            type: AppSnackType.warning,
          );
        }
        return;
      }

      if (!context.mounted || file == null) return;
      final XFile selectedFile = file;

      final ReportUploadImageValidation validation =
          await validateReportUploadImage(selectedFile);
      if (!validation.isSupported) {
        if (context.mounted) {
          AppSnack.show(
            context,
            message: context.l10n.reportFlowUnsupportedPhotoFormatSnack,
            type: AppSnackType.warning,
          );
        }
        continue;
      }

      final PhotoReviewResult? result =
          await AppBottomSheet.show<PhotoReviewResult>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.transparent,
            builder: (_) => PhotoReviewSheet(file: selectedFile),
          );

      if (!context.mounted) return;

      if (result == PhotoReviewResult.retake) {
        continue;
      }

      if (result == PhotoReviewResult.use) {
        AppHaptics.tap();
        await controller.addPhoto(selectedFile);
        scheduleDraftSave();
        if (context.mounted && MediaQuery.supportsAnnounceOf(context)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted || !MediaQuery.supportsAnnounceOf(context)) {
              return;
            }
            SemanticsService.sendAnnouncement(
              View.of(context),
              context.l10n.reportSemanticsPhotoAdded(
                controller.draft.photos.length,
                ReportFieldLimits.maxPhotos,
              ),
              Directionality.of(context),
            );
          });
        }
      }
      return;
    }
  } finally {
    if (context.mounted) {
      controller.setProcessingPhotoFlow(value: false);
    }
  }
}
