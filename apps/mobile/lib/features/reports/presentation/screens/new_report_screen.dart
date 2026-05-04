import 'dart:async';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/new_report_controller.dart';
import 'package:chisto_mobile/features/reports/domain/draft/new_report_flow_policy.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/new_report_submit_ui_flow.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen_post_frame.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_wizard_view.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_review_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_source_modal.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_widgets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({
    super.key,
    this.initialPhoto,
    this.entryLabel,
    this.entryHint,
  });

  final XFile? initialPhoto;
  final String? entryLabel;
  final String? entryHint;

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen>
    with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();
  final int _maxTitleLength = 120;
  final int _maxDescriptionLength = 500;

  late final NewReportController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = NewReportController(initialPhoto: widget.initialPhoto);
    _titleController.text = _controller.draft.title;
    _descriptionController.text = _controller.draft.description;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        runNewReportScreenPostFrameDraftRestore(
          context: context,
          controller: _controller,
          titleController: _titleController,
          descriptionController: _descriptionController,
          hasInitialPhoto: widget.initialPhoto != null,
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(
        _controller.flushPendingPersist(
          titleText: _titleController.text,
          descriptionText: _descriptionController.text,
        ),
      );
    }
  }

  @override
  void deactivate() {
    _controller.clearDidAnnounceLocationStep();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _titleController.dispose();
    _titleFocus.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
    _controller.scheduleAutosave(
      titleText: _titleController.text,
      descriptionText: _descriptionController.text,
    );
  }

  void _goToStage(ReportStage stage, {bool unfocusFirst = true}) {
    _controller.goToStage(stage, unfocusFirst: unfocusFirst);
    unawaited(
      _controller.flushPendingPersist(
        titleText: _titleController.text,
        descriptionText: _descriptionController.text,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.supportsAnnounceOf(context)) return;
      final String label = stage.config(context.l10n).infoTitle;
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.l10n.semanticsCurrentReportStep(label),
        Directionality.of(context),
      );
    });
  }

  void _goToFirstInvalidStage() {
    final ReportStage? stage =
        NewReportFlowPolicy.firstBlockingStage(_controller.draft);
    if (stage == null) {
      return;
    }
    _goToStage(stage, unfocusFirst: false);
    _controller.highlightStage(stage);
  }

  void _handlePrimaryAction() {
    if (_controller.currentStage == ReportStage.review) {
      unawaited(_submit());
      return;
    }
    if (!_controller.canAdvanceFromCurrentStage()) {
      _controller.markStageAttempted(_controller.currentStage);
      _controller.highlightStage(_controller.currentStage);
      return;
    }
    final ReportStage next =
        ReportStage.values[_controller.currentStageIndex + 1];
    _goToStage(next, unfocusFirst: false);
    if (!MediaQuery.disableAnimationsOf(context)) {
      AppHaptics.settle();
    }
  }

  Future<void> _addPhoto() async {
    if (_controller.draft.photos.length >= 5 ||
        _controller.isProcessingPhotoFlow) {
      return;
    }

    AppHaptics.tap();
    final ImageSource? source = await showPhotoSourceModal(context);
    if (source == null || !mounted) return;
    await _pickAndReview(source);
  }

  Future<void> _pickAndReview(ImageSource source) async {
    if (_controller.isProcessingPhotoFlow) return;

    _controller.setProcessingPhotoFlow(true);

    try {
      while (mounted) {
        XFile? file;
        try {
          file = await _imagePicker.pickImage(
            source: source,
            preferredCameraDevice: CameraDevice.rear,
          );
        } on PlatformException {
          if (mounted) {
            AppSnack.show(
              context,
              message: context.l10n.reportFlowCameraUnavailableSnack,
              type: AppSnackType.warning,
            );
          }
          return;
        }

        if (!mounted || file == null) return;
        final XFile selectedFile = file;

        final PhotoReviewResult? result =
            await showModalBottomSheet<PhotoReviewResult>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.transparent,
              elevation: 0,
              builder: (_) => PhotoReviewSheet(file: selectedFile),
            );

        if (!mounted) return;

        if (result == PhotoReviewResult.retake) {
          continue;
        }

        if (result == PhotoReviewResult.use) {
          final bool wasEmpty = _controller.draft.photos.isEmpty;
          await _controller.addPhoto(selectedFile);
          if (wasEmpty) {
            AppHaptics.success();
          }
          _scheduleDraftSave();
        }
        return;
      }
    } finally {
      if (mounted) {
        _controller.setProcessingPhotoFlow(false);
      }
    }
  }

  Future<void> _submit() async {
    if (_controller.submitting) return;
    await _controller.flushPendingPersist(
      titleText: _titleController.text,
      descriptionText: _descriptionController.text,
    );
    if (!mounted) return;
    _controller.beginSubmitAttempt();

    if (!_controller.canSubmit) {
      AppSnack.show(
        context,
        message: context.l10n.reportFinishStepsSnack,
        type: AppSnackType.warning,
      );
      _goToFirstInvalidStage();
      return;
    }

    AppHaptics.medium();
    _controller.beginSubmittingPhase();

    try {
      final String trimmedTitle = _controller.draft.title.trim();
      final ReportSubmitResult result = await _controller.submitReport();
      if (!mounted) return;
      ServiceLocator.instance.reportsListSession.onSubmitSucceeded(
        result: result,
        title: trimmedTitle,
        draft: _controller.draft,
      );
      _controller.setSuppressLocalDraftPersist(true);
      ServiceLocator.instance.profileNeedsRefresh.value++;
      _controller.markSubmitSentPhase();
      if (mounted && MediaQuery.supportsAnnounceOf(context)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !MediaQuery.supportsAnnounceOf(context)) {
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
        draft: _controller.draft,
        result: result,
        onResetSubmittingUi: () async {
          if (mounted) {
            _controller.resetSubmittingUi();
          }
        },
      );
      if (!mounted || nav == null) {
        return;
      }
      await ServiceLocator.instance.reportDraftRepository.clear();
      if (!mounted) {
        return;
      }
      switch (nav) {
        case NewReportPostSubmitReportAnother():
          _controller.resetDraftAndStartOver();
          _titleController.text = '';
          _descriptionController.text = '';
        case NewReportPostSubmitExit(:final Object? popResult):
          Navigator.of(context).pop(popResult);
      }
    } on AppError catch (e) {
      if (!mounted) return;
      _controller.resetSubmittingUi();
      final bool handled = await NewReportSubmitUiFlow.handleSubmitAppError(
        context,
        e,
        _controller.loadReportingCapacity,
      );
      if (!mounted) return;
      if (!handled) {
        _controller.setApiError(e);
      }
    } catch (e) {
      if (!mounted) return;
      _controller.endSubmitWithError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        await _controller.flushPendingPersist(
          titleText: _titleController.text,
          descriptionText: _descriptionController.text,
        );
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop(result);
      },
      child: ChangeNotifierProvider<NewReportController>.value(
        value: _controller,
        child: NewReportWizardView(
          entryLabel: widget.entryLabel,
          entryHint: widget.entryHint,
          hasInitialPhoto: widget.initialPhoto != null,
          titleController: _titleController,
          descriptionController: _descriptionController,
          titleFocus: _titleFocus,
          descriptionFocus: _descriptionFocus,
          maxTitleLength: _maxTitleLength,
          maxDescriptionLength: _maxDescriptionLength,
          onAddPhoto: _addPhoto,
          onPrimary: _handlePrimaryAction,
          onRetrySubmit: _submit,
          onGoToStage: _goToStage,
          onScheduleDraftSave: _scheduleDraftSave,
        ),
      ),
    );
  }
}
