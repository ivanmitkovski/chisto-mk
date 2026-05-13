import 'dart:async';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_draft_saved_label.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/new_report_controller.dart';
import 'package:chisto_mobile/features/reports/domain/draft/new_report_flow_policy.dart';
import 'package:chisto_mobile/features/reports/domain/report_field_limits.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_widgets.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_details_form_fields.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_evidence_stage_body.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_flow_bottom_bar.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_flow_header.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_location_stage_body.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_review_stage_body.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_stage_help_modal.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_stage_shell.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_upload_prep_progress.dart';
import 'package:chisto_mobile/features/reports/presentation/theme/report_tokens.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

/// Wizard body for [NewReportScreen]; keeps [BuildContext] usage to side-effects only.
class NewReportWizardView extends StatelessWidget {
  const NewReportWizardView({
    super.key,
    required this.entryLabel,
    required this.entryHint,
    required this.hasInitialPhoto,
    required this.titleController,
    required this.descriptionController,
    required this.titleFocus,
    required this.descriptionFocus,
    required this.maxTitleLength,
    required this.maxDescriptionLength,
    required this.onAddPhoto,
    required this.onPrimary,
    required this.onRetrySubmit,
    required this.onGoToStage,
    required this.onScheduleDraftSave,
    required this.uploadPrepListenable,
    required this.showDraftRestoredChip,
  });

  final String? entryLabel;
  final String? entryHint;
  final bool hasInitialPhoto;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final FocusNode titleFocus;
  final FocusNode descriptionFocus;
  final int maxTitleLength;
  final int maxDescriptionLength;
  final Future<void> Function() onAddPhoto;
  final VoidCallback onPrimary;
  final Future<void> Function() onRetrySubmit;
  final void Function(ReportStage stage, {bool unfocusFirst}) onGoToStage;
  final VoidCallback onScheduleDraftSave;
  final ValueListenable<ReportUploadPrepProgress?> uploadPrepListenable;
  final bool showDraftRestoredChip;

  Future<void> _openStageHelp(
    BuildContext context,
    NewReportController controller, {
    required ReportStage stage,
    String? infoExtra,
  }) async {
    await showNewReportStageHelpModal(
      context,
      stage,
      onFlowHelpOpened: controller.markSeenReportHelp,
      infoExtra: infoExtra,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewReportController>(
      builder: (BuildContext context, NewReportController c, _) {
        final String? evidenceHelpExtra =
            entryHint ??
            (hasInitialPhoto ? context.l10n.reportEntryHintCamera : null);

        bool isStageComplete(ReportStage stage) =>
            NewReportFlowPolicy.isStageComplete(stage, c.draft);

        bool canNavigateToStage(ReportStage stage) =>
            NewReportFlowPolicy.canNavigateToStage(
              target: stage,
              current: c.currentStage,
              draft: c.draft,
            );

        Widget scrollWithSurface({
          required ReportStage stage,
          required Widget body,
          String? helpExtra,
        }) {
          return NewReportStageScrollBody(
            currentStage: c.currentStage,
            apiError: c.apiError,
            onDismissApiError: () => c.setApiError(null),
            onRetryApiError: c.apiError?.retryable == true
                ? () {
                    c.setApiError(null);
                    unawaited(onRetrySubmit());
                  }
                : null,
            child: NewReportStageSurface(
              stage: stage,
              isHighlighted: c.highlightedStage == stage,
              reportFlowPrefsLoaded: c.reportFlowPrefsLoaded,
              hasSeenReportHelpHint: c.hasSeenReportHelpHint,
              onDismissFlowHelpHint: () async {
                AppHaptics.light();
                await c.markSeenReportHelp();
                onScheduleDraftSave();
              },
              onPressedHelp: () {
                unawaited(
                  _openStageHelp(
                    context,
                    c,
                    stage: stage,
                    infoExtra: helpExtra,
                  ),
                );
              },
              child: body,
            ),
          );
        }

        Widget buildCurrentStage() {
          switch (c.currentStage) {
            case ReportStage.evidence:
              return scrollWithSurface(
                stage: ReportStage.evidence,
                helpExtra: evidenceHelpExtra,
                body: NewReportEvidenceStageBody(
                  draft: c.draft,
                  evidenceTipDismissed: c.evidenceTipDismissed,
                  attemptedStages: c.attemptedStages,
                  onDismissTip: () {
                    AppHaptics.light();
                    c.setEvidenceTipDismissed(true);
                    onScheduleDraftSave();
                  },
                  onAddPhoto: onAddPhoto,
                  onRemovePhoto: (int i) {
                    unawaited(() async {
                      await c.removePhoto(i);
                      onScheduleDraftSave();
                      if (context.mounted &&
                          MediaQuery.supportsAnnounceOf(context)) {
                        SemanticsService.sendAnnouncement(
                          View.of(context),
                          context.l10n.reportSemanticsPhotoRemoved(
                            c.draft.photos.length,
                            ReportFieldLimits.maxPhotos,
                          ),
                          Directionality.of(context),
                        );
                      }
                    }());
                  },
                ),
              );
            case ReportStage.details:
              return scrollWithSurface(
                stage: ReportStage.details,
                body: NewReportDetailsFormFields(
                  draft: c.draft,
                  attemptedStages: c.attemptedStages,
                  titleController: titleController,
                  descriptionController: descriptionController,
                  titleFocus: titleFocus,
                  descriptionFocus: descriptionFocus,
                  maxTitleLength: maxTitleLength,
                  maxDescriptionLength: maxDescriptionLength,
                  onTitleChanged: (String value) {
                    c.updateTitle(value);
                    onScheduleDraftSave();
                  },
                  onDescriptionChanged: (String value) {
                    c.updateDescription(value);
                    onScheduleDraftSave();
                  },
                  onSeverityChanged: (int severity) {
                    c.updateSeverity(severity);
                    onScheduleDraftSave();
                  },
                  onCategorySelected: (ReportCategory cat) {
                    c.updateCategory(cat);
                    onScheduleDraftSave();
                  },
                  onCleanupEffort: (CleanupEffort effort) {
                    AppHaptics.light();
                    c.setCleanupEffort(effort);
                    onScheduleDraftSave();
                  },
                ),
              );
            case ReportStage.location:
              if (!c.hasValidLocation && !c.didAnnounceLocationStep) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  if (MediaQuery.supportsAnnounceOf(context)) {
                    SemanticsService.sendAnnouncement(
                      View.of(context),
                      context.l10n.reportSemanticsLocationPinThenConfirm,
                      Directionality.of(context),
                    );
                  }
                  c.markLocationStepAnnounced();
                });
              }
              return scrollWithSurface(
                stage: ReportStage.location,
                body: NewReportLocationStageBody(
                  initialLatitude: c.draft.latitude,
                  initialLongitude: c.draft.longitude,
                  onLocationChanged: (LocationPickerResult result) {
                    c.onLocationChanged(result);
                    onScheduleDraftSave();
                  },
                  showAdvanceBlockedHint:
                      c.attemptedStages.contains(ReportStage.location) &&
                      !c.hasValidLocation,
                ),
              );
            case ReportStage.review:
              return scrollWithSurface(
                stage: ReportStage.review,
                body: NewReportReviewStageBody(
                  draft: c.draft,
                  hasValidLocation: c.hasValidLocation,
                  canSubmit: c.canSubmit,
                  reportCapacity: c.reportCapacity,
                  onGoToEvidence: () => onGoToStage(ReportStage.evidence),
                  onGoToDetails: () => onGoToStage(ReportStage.details),
                  onGoToLocation: () => onGoToStage(ReportStage.location),
                ),
              );
          }
        }

        final String savedLabel =
            reportDraftSavedIndicator(context.l10n, c.lastPersistedAtMs);

        return Scaffold(
          backgroundColor: AppColors.panelBackground,
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      0,
                    ),
                    child: NewReportFlowHeader(
                      title: entryLabel ??
                          (hasInitialPhoto
                              ? context.l10n.reportEntryLabelCamera
                              : context.l10n.reportEntryLabelGuided),
                      currentStage: c.currentStage,
                      currentStageIndex: c.currentStageIndex,
                      isStageComplete: isStageComplete,
                      canNavigateToStage: canNavigateToStage,
                      onBackFromEvidence: () => Navigator.of(context).maybePop(),
                      onBackToPreviousStage: () => onGoToStage(
                        ReportStage.values[c.currentStageIndex - 1],
                      ),
                      onTapStage: (ReportStage stage) => onGoToStage(stage),
                      showDraftRestoredChip: showDraftRestoredChip,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.emphasized,
                      switchOutCurve: AppMotion.emphasized,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final Animation<Offset> slide = Tween<Offset>(
                          begin: Offset(ReportTokens.wizardStageSlideOffset, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slide,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<ReportStage>(c.currentStage),
                        child: buildCurrentStage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Material(
            color: AppColors.panelBackground,
            elevation: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.reportDividerLight,
                  ),
                  ValueListenableBuilder<ReportUploadPrepProgress?>(
                    valueListenable: uploadPrepListenable,
                    builder: (
                      BuildContext context,
                      ReportUploadPrepProgress? prep,
                      _,
                    ) {
                      return NewReportFlowBottomBar(
                        draftAutosaveLabel:
                            savedLabel.isNotEmpty ? savedLabel : null,
                        currentStage: c.currentStage,
                        submitting: c.submitting,
                        submitPhase: c.submitPhase,
                        uploadPrepProgress: prep,
                        onPrimary: onPrimary,
                        onBack: () => onGoToStage(
                          ReportStage.values[c.currentStageIndex - 1],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
