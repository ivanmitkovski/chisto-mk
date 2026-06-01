import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/application/report_wizard_submit_port.dart';
import 'package:feature_reports/src/domain/draft/new_report_flow_policy.dart';
import 'package:feature_reports/src/domain/report_field_limits.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_controller.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_submit_ui_flow.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_wizard_state.dart';
import 'package:feature_reports/src/presentation/screens/new_report_screen_post_frame.dart';
import 'package:feature_reports/src/presentation/screens/new_report_wizard_skeleton.dart';
import 'package:feature_reports/src/presentation/screens/new_report_wizard_view.dart';
import 'package:feature_reports/src/presentation/theme/report_tokens.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/new_report_widgets.dart';
import 'package:feature_reports/src/presentation/widgets/photo_review_sheet.dart';
import 'package:feature_reports/src/presentation/widgets/photo_source_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class NewReportScreen extends ConsumerStatefulWidget {
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
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen>
    with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();

  late NewReportController _notifierRef;

  bool _isRestoringDraft = true;
  bool _showDraftRestoredChip = false;
  Timer? _draftChipTimer;

  NewReportController get _controller =>
      ref.read(newReportControllerProvider(widget.initialPhoto).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifierRef = _controller;
    _titleController.text = _notifierRef.draft.title;
    _descriptionController.text = _notifierRef.draft.description;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        runNewReportScreenPostFrameDraftRestore(
          context: context,
          controller: _notifierRef,
          titleController: _titleController,
          descriptionController: _descriptionController,
          hasInitialPhoto: widget.initialPhoto != null,
          onRestoreUiReady: () {
            if (!mounted) return;
            setState(() => _isRestoringDraft = false);
          },
          onDraftRestoredVisual: () {
            if (!mounted) return;
            setState(() => _showDraftRestoredChip = true);
            _draftChipTimer?.cancel();
            _draftChipTimer = Timer(const Duration(seconds: 3), () {
              if (!mounted) return;
              setState(() => _showDraftRestoredChip = false);
            });
          },
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
  void dispose() {
    if (_controller.shouldPersistOnDispose(
      titleText: _titleController.text,
      descriptionText: _descriptionController.text,
    )) {
      unawaited(
        _controller.flushPendingPersist(
          titleText: _titleController.text,
          descriptionText: _descriptionController.text,
        ),
      );
    }
    _draftChipTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
    final ReportStage? stage = NewReportFlowPolicy.firstBlockingStage(
      _controller.draft,
    );
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
  }

  Future<void> _addPhoto() async {
    if (_controller.draft.photos.length >= ReportFieldLimits.maxPhotos ||
        _controller.isProcessingPhotoFlow) {
      return;
    }

    final ImageSource? source = await showPhotoSourceModal(context);
    if (source == null || !mounted) return;
    await _pickAndReview(source);
  }

  Future<void> _pickAndReview(ImageSource source) async {
    if (_controller.isProcessingPhotoFlow) return;

    _controller.setProcessingPhotoFlow(value: true);

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
          AppHaptics.tap();
          await _controller.addPhoto(selectedFile);
          _scheduleDraftSave();
          if (mounted && MediaQuery.supportsAnnounceOf(context)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !MediaQuery.supportsAnnounceOf(context)) {
                return;
              }
              SemanticsService.sendAnnouncement(
                View.of(context),
                context.l10n.reportSemanticsPhotoAdded(
                  _controller.draft.photos.length,
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
      if (mounted) {
        _controller.setProcessingPhotoFlow(value: false);
      }
    }
  }

  Future<void> _submit() async {
    await NewReportSubmitUiFlow.runSubmit(
      context: context,
      controller: _controller,
      titleController: _titleController,
      descriptionController: _descriptionController,
      bindings: NewReportSubmitBindings(
        reportsListSession: ref.read(reportsListSessionProvider),
        reportDraftRepository: ref.read(reportDraftRepositoryProvider),
      ),
      onCannotSubmit: () {
        if (!mounted) {
          return;
        }
        AppSnack.show(
          context,
          message: context.l10n.reportFinishStepsSnack,
          type: AppSnackType.warning,
        );
        _goToFirstInvalidStage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final NewReportWizardState wizardState = ref.watch(
      newReportControllerProvider(widget.initialPhoto),
    );
    final ReportWizardSubmitPort submitPort = ref.read(
      reportWizardSubmitPortProvider,
    );
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
      child: _isRestoringDraft
          ? const Scaffold(
              backgroundColor: AppColors.panelBackground,
              body: SafeArea(bottom: false, child: NewReportWizardSkeleton()),
            )
          : NewReportWizardView(
              entryLabel: widget.entryLabel,
              entryHint: widget.entryHint,
              hasInitialPhoto: widget.initialPhoto != null,
              titleController: _titleController,
              descriptionController: _descriptionController,
              titleFocus: _titleFocus,
              descriptionFocus: _descriptionFocus,
              maxTitleLength: ReportTokens.maxTitleLength,
              maxDescriptionLength: ReportTokens.maxDescriptionLength,
              onAddPhoto: _addPhoto,
              onPrimary: _handlePrimaryAction,
              onRetrySubmit: _submit,
              onGoToStage: _goToStage,
              onScheduleDraftSave: _scheduleDraftSave,
              uploadPrepListenable: submitPort.uploadPrepProgress,
              showDraftRestoredChip: _showDraftRestoredChip,
              controller: _controller,
              wizardState: wizardState,
            ),
    );
  }
}
