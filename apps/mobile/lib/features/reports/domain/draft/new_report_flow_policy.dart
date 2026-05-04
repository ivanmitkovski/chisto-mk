import 'package:chisto_mobile/features/reports/domain/draft/report_stage.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

/// Pure rules for the multi-step new-report flow (stages, navigation, completion).
class NewReportFlowPolicy {
  const NewReportFlowPolicy._();

  static bool hasValidLocation(ReportDraft draft) {
    final double? lat = draft.latitude;
    final double? lng = draft.longitude;
    return lat != null && lng != null && isReportLocationInMacedonia(lat, lng);
  }

  static bool canSubmit(ReportDraft draft) {
    return draft.isValid && hasValidLocation(draft);
  }

  static bool isStageComplete(ReportStage stage, ReportDraft draft) {
    switch (stage) {
      case ReportStage.evidence:
        return draft.hasPhotos;
      case ReportStage.details:
        return draft.hasCategory && draft.hasTitle;
      case ReportStage.location:
        return hasValidLocation(draft);
      case ReportStage.review:
        return canSubmit(draft);
    }
  }

  static int currentStageIndex(ReportStage current) =>
      ReportStage.values.indexOf(current);

  static bool canNavigateToStage({
    required ReportStage target,
    required ReportStage current,
    required ReportDraft draft,
  }) {
    final int targetIndex = ReportStage.values.indexOf(target);
    final int currentIndex = currentStageIndex(current);
    if (targetIndex <= currentIndex) {
      return true;
    }
    if (target == ReportStage.details) {
      return draft.hasPhotos;
    }
    if (target == ReportStage.location) {
      return draft.hasPhotos && draft.hasCategory && draft.hasTitle;
    }
    return canSubmit(draft);
  }

  static bool canAdvanceFromCurrentStage({
    required ReportStage current,
    required ReportDraft draft,
  }) {
    return isStageComplete(current, draft);
  }

  /// First stage that blocks submission, or null if the draft is submittable.
  static ReportStage? firstBlockingStage(ReportDraft draft) {
    if (!draft.hasPhotos) {
      return ReportStage.evidence;
    }
    if (!draft.hasCategory) {
      return ReportStage.details;
    }
    if (!draft.hasTitle) {
      return ReportStage.details;
    }
    if (!hasValidLocation(draft)) {
      return ReportStage.location;
    }
    return null;
  }
}
