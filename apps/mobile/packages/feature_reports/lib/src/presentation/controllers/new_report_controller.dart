import 'dart:async';
import 'dart:io';

import 'package:chisto_infrastructure/core/concurrency/single_flight.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/application/report_wizard_submit_port.dart';
import 'package:feature_reports/src/application/reports_providers.dart';
import 'package:feature_reports/src/data/outbox/report_draft_repository.dart';
import 'package:feature_reports/src/data/report_flow_preferences.dart';
import 'package:feature_reports/src/data/report_upload_image_validator.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/domain/draft/new_report_flow_policy.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/models/report_wizard_restore_snapshot.dart';
import 'package:feature_reports/src/domain/report_field_limits.dart';
import 'package:feature_reports/src/domain/report_input_sanitizer.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_submit_error_display.dart';
import 'package:feature_reports/src/presentation/controllers/new_report_wizard_state.dart';
import 'package:feature_reports/src/presentation/controllers/wizard_autosave_debouncer.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/new_report_widgets.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_stage.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/resume_with_incoming_photo_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'new_report_controller.g.dart';

/// Wizard controller for [NewReportScreen] (no [BuildContext]).
@riverpod
class NewReportController extends _$NewReportController {
  late final XFile? _initialPhoto;
  late final ReportFlowPreferences _reportFlowPreferences;
  late final ReportDraftRepository _draftRepo;
  late final ReportsApiRepository _reportsApi;
  late final ReportWizardSubmitPort _reportSubmitPort;
  final WizardAutosaveDebouncer _autosaveDebouncer = WizardAutosaveDebouncer();
  Timer? _highlightTimer;
  Future<void> _photoOpChain = Future<void>.value();
  final SingleFlight<ReportSubmitResult> _submitFlight =
      SingleFlight<ReportSubmitResult>();
  bool _alive = true;

  @override
  NewReportWizardState build(XFile? initialPhoto) {
    _alive = true;
    _initialPhoto = initialPhoto;
    _reportFlowPreferences = const ReportFlowPreferences();
    _draftRepo = ref.watch(reportDraftRepositoryProvider);
    _reportsApi = ref.watch(reportsApiRepositoryProvider);
    _reportSubmitPort = ref.watch(reportWizardSubmitPortProvider);

    ref.onDispose(() {
      _alive = false;
      _highlightTimer?.cancel();
      _autosaveDebouncer.dispose();
    });

    _reportFlowPreferences.hasSeenReportHelpHint.then((bool v) {
      if (!_alive) return;
      state = state.copyWith(
        reportFlowPrefsLoaded: true,
        hasSeenReportHelpHint: v,
      );
    });

    return NewReportWizardState(
      incomingPhotoMergeResolved: initialPhoto == null,
      suppressLocalDraftPersist: initialPhoto != null,
    );
  }

  Future<void> _seedInitialPhoto(XFile initialPhoto) async {
    await _enqueuePhotoOp(() async {
      try {
        final XFile managed = await _draftRepo.registerPhoto(initialPhoto);
        _setDraft(state.draft.copyWith(photos: <XFile>[managed]));
      } on UnsupportedReportUploadImageException {
        chistoReportsBreadcrumb(
          'report_draft',
          'initial_photo_unsupported_format',
        );
      } catch (e, st) {
        chistoReportsBreadcrumb(
          'report_draft',
          'initial_photo_import_failed',
          data: <String, Object?>{'error': e.runtimeType.toString()},
        );
        await Sentry.captureException(e, stackTrace: st);
        _setDraft(state.draft.copyWith(photos: <XFile>[initialPhoto]));
      }
    });
  }

  Future<T> _enqueuePhotoOp<T>(Future<T> Function() op) {
    final Future<T> run = _photoOpChain.then((_) => op());
    _photoOpChain = run.then((_) {}).catchError((Object e, StackTrace st) {
      AppLog.warn('new_report photo op chain', error: e, stackTrace: st);
    });
    return run;
  }

  ReportDraft get draft => state.draft;
  bool get submitting => state.submitting;
  String? get submitPhase => state.submitPhase;
  bool get isProcessingPhotoFlow => state.isProcessingPhotoFlow;
  bool get evidenceTipDismissed => state.evidenceTipDismissed;
  Set<ReportStage> get attemptedStages => state.attemptedStages;
  ReportStage get currentStage => state.currentStage;
  ReportStage? get highlightedStage => state.highlightedStage;
  bool get didAnnounceLocationStep => state.didAnnounceLocationStep;
  AppError? get apiError => state.apiError;
  ReportCapacity? get reportCapacity => state.reportCapacity;
  bool get reportFlowPrefsLoaded => state.reportFlowPrefsLoaded;
  bool get hasSeenReportHelpHint => state.hasSeenReportHelpHint;
  int? get lastPersistedAtMs => state.lastPersistedAtMs;
  Object? get restoreError => state.restoreError;

  bool get hasValidLocation =>
      NewReportFlowPolicy.hasValidLocation(state.draft);
  bool get canSubmit => NewReportFlowPolicy.canSubmit(state.draft);
  bool get wizardSubmitLocked => state.wizardSubmitLocked;
  int get currentStageIndex =>
      NewReportFlowPolicy.currentStageIndex(state.currentStage);

  void setSuppressLocalDraftPersist({required bool value}) {
    state = state.copyWith(suppressLocalDraftPersist: value);
  }

  Future<ReportDraftSummary> peekSavedDraft() => _draftRepo.summary();

  /// Seeds the camera/picker photo after the incoming-photo merge gate (or when no draft).
  Future<void> seedInitialPhotoFromPending() async {
    final XFile? incoming = _initialPhoto;
    if (incoming == null || state.incomingPhotoMergeResolved) {
      return;
    }
    await _seedInitialPhoto(incoming);
    _markIncomingPhotoMergeResolved();
  }

  void _markIncomingPhotoMergeResolved() {
    state = state.copyWith(
      incomingPhotoMergeResolved: true,
      suppressLocalDraftPersist: false,
    );
  }

  /// Resolves conflict between [initialPhoto] and an existing SQLite draft.
  Future<ReportDraftLoadResult?> resolveIncomingPhotoMerge(
    ResumeWithIncomingChoice choice,
  ) async {
    switch (choice) {
      case ResumeWithIncomingChoice.continueDraft:
        chistoReportsBreadcrumb(
          'report_draft',
          'incoming_photo_choice_continue',
        );
        _markIncomingPhotoMergeResolved();
        return restoreSavedDraft();
      case ResumeWithIncomingChoice.replaceDraft:
        chistoReportsBreadcrumb(
          'report_draft',
          'incoming_photo_choice_replace',
        );
        final XFile incoming = _initialPhoto!;
        await discardDraft();
        await _seedInitialPhoto(incoming);
        _markIncomingPhotoMergeResolved();
        await persistWizardDraft(
          titleText: state.draft.title,
          descriptionText: state.draft.description,
        );
        return null;
      case ResumeWithIncomingChoice.addPhoto:
        chistoReportsBreadcrumb('report_draft', 'incoming_photo_choice_add');
        final XFile incoming = _initialPhoto!;
        _markIncomingPhotoMergeResolved();
        final ReportDraftLoadResult r = await restoreSavedDraft();
        await addPhoto(incoming);
        return r;
    }
  }

  /// Loads SQLite + managed photos; returns whether the user should see the resume banner.
  Future<ReportDraftLoadResult> restoreSavedDraft() async {
    state = state.copyWith(clearRestoreError: true);
    if (_initialPhoto != null && !state.incomingPhotoMergeResolved) {
      return const ReportDraftLoadResult.empty();
    }
    try {
      final ReportDraftLoadResult r = await _draftRepo.loadDraft();
      final ReportWizardRestoreSnapshot? restoreSnap = r.restore;
      if (!r.hasDraft || restoreSnap == null) {
        return r;
      }
      final ReportWizardRestoreSnapshot snap = restoreSnap;
      final ReportDraft saved = snap.draft;
      final String title = snap.title.isNotEmpty ? snap.title : saved.title;
      final String description = snap.description.isNotEmpty
          ? snap.description
          : saved.description;
      ReportStage restoredStage = ReportStage.evidence;
      if (snap.currentStageName != null && snap.currentStageName!.isNotEmpty) {
        try {
          restoredStage = ReportStage.values.byName(snap.currentStageName!);
        } catch (_) {
          restoredStage = ReportStage.evidence;
        }
      }
      final Set<ReportStage> restoredAttempted = <ReportStage>{};
      for (final String name in snap.attemptedStageNames) {
        try {
          restoredAttempted.add(ReportStage.values.byName(name));
        } catch (e, st) {
          AppLog.warn(
            'new_report: unknown attempted stage name skipped',
            error: e,
            stackTrace: st,
          );
        }
      }
      state = state.copyWith(
        draft: saved.copyWith(title: title, description: description),
        currentStage: restoredStage,
        attemptedStages: restoredAttempted,
        lastPersistedAtMs: snap.lastPersistedAtMs ?? snap.updatedAtMs,
      );
      return r;
    } catch (e, st) {
      state = state.copyWith(restoreError: e);
      chistoReportsBreadcrumb(
        'report_draft',
        'restore_controller_failed',
        data: <String, Object?>{'error': e.runtimeType.toString()},
      );
      await Sentry.captureException(e, stackTrace: st);
      return const ReportDraftLoadResult.empty();
    }
  }

  Future<void> markSeenReportHelp() async {
    await _reportFlowPreferences.setSeenReportHelpHint();
    state = state.copyWith(hasSeenReportHelpHint: true);
  }

  void clearDidAnnounceLocationStep() {
    state = state.copyWith(didAnnounceLocationStep: false);
  }

  void markLocationStepAnnounced() {
    state = state.copyWith(didAnnounceLocationStep: true);
  }

  Future<void> loadReportingCapacity() async {
    try {
      final ReportCapacity capacity = await _reportsApi.getReportingCapacity();
      state = state.copyWith(reportCapacity: capacity);
    } catch (e, st) {
      chistoReportsBreadcrumb(
        'report_draft',
        'capacity_load_failed',
        data: <String, Object?>{'error': e.runtimeType.toString()},
      );
      await Sentry.captureException(e, stackTrace: st);
    }
  }

  bool canNavigateToStage(ReportStage stage) =>
      NewReportFlowPolicy.canNavigateToStage(
        target: stage,
        current: state.currentStage,
        draft: state.draft,
      );

  void highlightStage(ReportStage stage) {
    _highlightTimer?.cancel();
    state = state.copyWith(highlightedStage: stage);
    _highlightTimer = Timer(AppMotion.loadingOverlayLoop, () {
      if (state.highlightedStage != stage) return;
      state = state.copyWith(clearHighlightedStage: true);
    });
  }

  void goToStage(ReportStage stage, {bool unfocusFirst = true}) {
    if (!canNavigateToStage(stage)) return;
    if (unfocusFirst) FocusManager.instance.primaryFocus?.unfocus();
    state = state.copyWith(
      currentStage: stage,
      clearHighlightedStage: true,
      didAnnounceLocationStep:
          !(stage != ReportStage.location) && state.didAnnounceLocationStep,
    );
  }

  bool canAdvanceFromCurrentStage() =>
      NewReportFlowPolicy.canAdvanceFromCurrentStage(
        current: state.currentStage,
        draft: state.draft,
      );

  void markStageAttempted(ReportStage stage) {
    state = state.copyWith(
      attemptedStages: <ReportStage>{...state.attemptedStages, stage},
    );
  }

  void setEvidenceTipDismissed({required bool value}) {
    state = state.copyWith(evidenceTipDismissed: value);
  }

  void _setDraft(ReportDraft next) {
    state = state.copyWith(draft: next);
  }

  void updateTitle(String value) => _setDraft(
    state.draft.copyWith(title: ReportInputSanitizer.clampTitle(value)),
  );
  void updateDescription(String value) => _setDraft(
    state.draft.copyWith(
      description: ReportInputSanitizer.clampDescription(value),
    ),
  );
  void updateSeverity(int severity) =>
      _setDraft(state.draft.copyWith(severity: severity));
  void updateCategory(ReportCategory cat) =>
      _setDraft(state.draft.copyWith(category: cat));
  void setCleanupEffort(CleanupEffort effort) =>
      _setDraft(state.draft.copyWith(cleanupEffort: effort));

  void onLocationChanged(LocationPickerResult result) {
    if (!result.isInMacedonia) {
      _setDraft(state.draft.copyWith(clearLocation: true));
      return;
    }
    final double lat = result.latitude;
    final double lng = result.longitude;
    if (!isReportLocationInMacedonia(lat, lng)) {
      _setDraft(state.draft.copyWith(clearLocation: true));
      return;
    }
    _setDraft(
      state.draft.copyWith(
        latitude: lat,
        longitude: lng,
        address: result.address,
      ),
    );
  }

  Future<void> addPhoto(XFile file) async {
    await _enqueuePhotoOp(() async {
      if (state.draft.photos.length >= ReportFieldLimits.maxPhotos) {
        return;
      }
      final XFile managed = await _draftRepo.registerPhoto(file);
      _setDraft(
        state.draft.copyWith(photos: <XFile>[...state.draft.photos, managed]),
      );
    });
  }

  Future<void> removePhoto(int index) async {
    await _enqueuePhotoOp(() async {
      final XFile removed = state.draft.photos[index];
      await _draftRepo.deleteDraftPhoto(removed.path);
      final List<XFile> updated = List<XFile>.from(state.draft.photos)
        ..removeAt(index);
      _setDraft(state.draft.copyWith(photos: updated));
    });
  }

  void setProcessingPhotoFlow({required bool value}) {
    state = state.copyWith(isProcessingPhotoFlow: value);
  }

  void setApiError(AppError? e) {
    state = state.copyWith(apiError: e, clearApiError: e == null);
  }

  void resetSubmittingUi() {
    state = state.copyWith(submitting: false, clearSubmitPhase: true);
  }

  void markSubmitSucceeded(ReportSubmitResult result) {
    state = state.copyWith(
      submittedReportId: result.reportId,
      lastSubmitResult: result,
    );
  }

  /// When [submitReportAndAwait] times out but the outbox row already succeeded.
  Future<ReportSubmitResult?> recoverResultIfWizardSucceeded() async {
    if (state.lastSubmitResult != null) {
      return state.lastSubmitResult;
    }
    final ReportOutboxEntry? row = await _draftRepo.getWizardDraftEntry();
    if (row == null || row.state != ReportOutboxState.succeeded) {
      return null;
    }
    final String? reportId = row.reportId;
    if (reportId == null || reportId.isEmpty) {
      return null;
    }
    final ReportSubmitResult recovered = ReportSubmitResult(
      reportId: reportId,
      siteId: '',
      isNewSite: false,
      pointsAwarded: 0,
    );
    if (_alive) {
      markSubmitSucceeded(recovered);
    }
    return recovered;
  }

  void resetDraftAndStartOver() {
    state = NewReportWizardState();
  }

  void scheduleAutosave({
    required String titleText,
    required String descriptionText,
  }) {
    if (state.suppressLocalDraftPersist ||
        state.submitting ||
        state.wizardSubmitLocked) {
      return;
    }
    if (!_shouldPersistWizardDraft(titleText, descriptionText)) {
      return;
    }
    _autosaveDebouncer.schedule(
      () => persistWizardDraft(
        titleText: titleText,
        descriptionText: descriptionText,
      ),
    );
  }

  Future<void> flushPendingPersist({
    required String titleText,
    required String descriptionText,
  }) async {
    _autosaveDebouncer.cancel();
    await persistWizardDraft(
      titleText: titleText,
      descriptionText: descriptionText,
    );
    chistoReportsBreadcrumb('report_draft', 'autosave_flushed');
  }

  bool _shouldPersistWizardDraft(String titleText, String descriptionText) {
    if (state.draft.hasPersistableWizardBody) {
      return true;
    }
    if (titleText.trim().isNotEmpty || descriptionText.trim().isNotEmpty) {
      return true;
    }
    if (state.currentStage != ReportStage.evidence) {
      return true;
    }
    if (state.attemptedStages.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> persistWizardDraft({
    required String titleText,
    required String descriptionText,
  }) async {
    if (state.suppressLocalDraftPersist ||
        state.submitting ||
        state.wizardSubmitLocked) {
      return;
    }
    if (!_shouldPersistWizardDraft(titleText, descriptionText)) {
      return;
    }
    try {
      final int now = DateTime.now().millisecondsSinceEpoch;
      await _draftRepo.save(
        draft: state.draft,
        title: titleText,
        description: descriptionText,
        currentStageName: state.currentStage.name,
        attemptedStageNames: state.attemptedStages
            .map((ReportStage e) => e.name)
            .toList(),
        lastPersistedAtMs: now,
      );
      if (_alive) {
        state = state.copyWith(lastPersistedAtMs: now);
      }
    } catch (e, st) {
      chistoReportsBreadcrumb(
        'report_draft',
        'persist_failed',
        data: <String, Object?>{'error': e.runtimeType.toString()},
      );
      await Sentry.captureException(e, stackTrace: st);
    }
  }

  Future<void> discardDraft() async {
    _autosaveDebouncer.cancel();
    await _draftRepo.clear();
    resetDraftAndStartOver();
  }

  bool shouldPersistOnDispose({
    required String titleText,
    required String descriptionText,
  }) {
    return !state.suppressLocalDraftPersist &&
        !state.submitting &&
        !state.wizardSubmitLocked &&
        _shouldPersistWizardDraft(titleText, descriptionText);
  }

  void beginSubmitAttempt() {
    state = state.copyWith(
      attemptedStages: Set<ReportStage>.from(ReportStage.values),
      clearApiError: true,
    );
  }

  void beginSubmittingPhase() {
    state = state.copyWith(
      submitting: true,
      submitPhase: state.draft.photos.isNotEmpty ? 'uploading' : 'creating',
    );
  }

  /// Synchronous guard against double-tap before any async flush/submit work.
  bool tryBeginSubmit() {
    if (state.wizardSubmitLocked ||
        state.submitting ||
        _submitFlight.isRunning) {
      return false;
    }
    beginSubmittingPhase();
    return true;
  }

  void markSubmitSentPhase() {
    state = state.copyWith(submitPhase: 'sent');
  }

  /// Drops draft photos whose managed files are missing (e.g. after a failed
  /// in-place compress). Submit proceeds text-only; upload phase surfaces skips.
  Future<void> pruneUnreachableDraftPhotos() async {
    final List<XFile> photos = state.draft.photos;
    if (photos.isEmpty) {
      return;
    }
    final List<XFile> kept = <XFile>[];
    for (final XFile x in photos) {
      try {
        final File f = File(x.path);
        if (f.existsSync() && f.lengthSync() > 0) {
          kept.add(x);
        }
      } on Object catch (err, st) {
        AppLog.warn(
          'pruneUnreachableDraftPhotos: skip ${x.path}',
          error: err,
          stackTrace: st,
          category: 'reports_wizard',
        );
      }
    }
    if (kept.length != photos.length) {
      _setDraft(state.draft.copyWith(photos: kept));
      AppLog.warn(
        'pruneUnreachableDraftPhotos: removed ${photos.length - kept.length} missing photo(s)',
        category: 'reports_wizard',
      );
    }
  }

  Future<ReportSubmitResult> submitReport() async {
    await pruneUnreachableDraftPhotos();
    return _submitFlight.run(
      () => _reportSubmitPort.submitReportAndAwait(
        draft: state.draft,
        title: ReportInputSanitizer.clampTitle(state.draft.title),
        description: ReportInputSanitizer.clampDescription(
          state.draft.description,
        ),
      ),
    );
  }

  void endSubmitWithError(Object e) {
    final AppError err = switch (e) {
      AppError() => NewReportSubmitErrorDisplay.humanizeSubmitErrorForBanner(e),
      TimeoutException() => AppError.timeout(),
      SocketException() => AppError.network(cause: e),
      HandshakeException() => AppError.network(cause: e),
      StateError(message: final String m) when m.contains('in-flight') =>
        const AppError(
          code: 'SUBMIT_IN_PROGRESS',
          message: '',
          retryable: true,
        ),
      StateError(message: final String m) when m.contains('disposed') =>
        const AppError(
          code: 'SUBMIT_FAILED_RETRYABLE',
          message: '',
          retryable: true,
        ),
      _ => const AppError(
        code: 'SUBMIT_FAILED_RETRYABLE',
        message: '',
        retryable: true,
      ),
    };
    state = state.copyWith(
      submitting: false,
      clearSubmitPhase: true,
      apiError: err,
    );
  }
}
