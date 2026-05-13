import 'dart:async';
import 'dart:io';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/application/report_wizard_submit_port.dart';
import 'package:chisto_mobile/features/reports/data/report_flow_preferences.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_wizard_restore_snapshot.dart';
import 'package:chisto_mobile/features/reports/domain/draft/new_report_flow_policy.dart';
import 'package:chisto_mobile/features/reports/domain/report_field_limits.dart';
import 'package:chisto_mobile/features/reports/domain/report_input_sanitizer.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/wizard_autosave_debouncer.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/resume_with_incoming_photo_dialog.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Wizard state for [NewReportScreen] (no [BuildContext]).
class NewReportController extends ChangeNotifier {
  NewReportController({
    XFile? initialPhoto,
    ReportFlowPreferences reportFlowPreferences = const ReportFlowPreferences(),
    required ReportDraftRepository draftRepository,
    required ReportsApiRepository reportsApiRepository,
    required ReportWizardSubmitPort reportSubmitPort,
  }) : _initialPhoto = initialPhoto,
       _incomingPhotoMergeResolved = initialPhoto == null,
       _reportFlowPreferences = reportFlowPreferences,
       _draftRepo = draftRepository,
       _reportsApi = reportsApiRepository,
       _reportSubmitPort = reportSubmitPort,
       _autosaveDebouncer = WizardAutosaveDebouncer() {
    _suppressLocalDraftPersist = initialPhoto != null;
    _reportFlowPreferences.hasSeenReportHelpHint.then((bool v) {
      if (_disposed) return;
      _reportFlowPrefsLoaded = true;
      _hasSeenReportHelpHint = v;
      notifyListeners();
    });
  }

  bool _disposed = false;

  Future<void> _seedInitialPhoto(XFile initialPhoto) async {
    await _enqueuePhotoOp(() async {
      try {
        final XFile managed = await _draftRepo.registerPhoto(initialPhoto);
        _draft = _draft.copyWith(photos: <XFile>[managed]);
        notifyListeners();
      } catch (e, st) {
        chistoReportsBreadcrumb(
          'report_draft',
          'initial_photo_import_failed',
          data: <String, Object?>{'error': e.runtimeType.toString()},
        );
        await Sentry.captureException(e, stackTrace: st);
        _draft = _draft.copyWith(photos: <XFile>[initialPhoto]);
        notifyListeners();
      }
    });
  }

  final XFile? _initialPhoto;
  final ReportFlowPreferences _reportFlowPreferences;
  final ReportDraftRepository _draftRepo;
  final ReportsApiRepository _reportsApi;
  final ReportWizardSubmitPort _reportSubmitPort;
  ReportDraft _draft = ReportDraft();
  bool _submitting = false;
  String? _submitPhase;
  bool _isProcessingPhotoFlow = false;
  bool _evidenceTipDismissed = false;
  final Set<ReportStage> _attemptedStages = <ReportStage>{};
  ReportStage _currentStage = ReportStage.evidence;
  ReportStage? _highlightedStage;
  bool _didAnnounceLocationStep = false;
  AppError? _apiError;
  ReportCapacity? _reportCapacity;
  bool _reportFlowPrefsLoaded = false;
  bool _hasSeenReportHelpHint = true;
  bool _suppressLocalDraftPersist = false;
  Timer? _highlightTimer;
  final WizardAutosaveDebouncer _autosaveDebouncer;
  int? _lastPersistedAtMs;
  Object? _restoreError;
  bool _incomingPhotoMergeResolved;

  Future<void> _photoOpChain = Future<void>.value();

  Future<T> _enqueuePhotoOp<T>(Future<T> Function() op) {
    final Future<T> run = _photoOpChain.then((_) => op());
    _photoOpChain = run.then((_) {}).catchError((_) {});
    return run;
  }

  ReportDraft get draft => _draft;
  bool get submitting => _submitting;
  String? get submitPhase => _submitPhase;
  bool get isProcessingPhotoFlow => _isProcessingPhotoFlow;
  bool get evidenceTipDismissed => _evidenceTipDismissed;
  Set<ReportStage> get attemptedStages => _attemptedStages;
  ReportStage get currentStage => _currentStage;
  ReportStage? get highlightedStage => _highlightedStage;
  bool get didAnnounceLocationStep => _didAnnounceLocationStep;
  AppError? get apiError => _apiError;
  ReportCapacity? get reportCapacity => _reportCapacity;
  bool get reportFlowPrefsLoaded => _reportFlowPrefsLoaded;
  bool get hasSeenReportHelpHint => _hasSeenReportHelpHint;
  int? get lastPersistedAtMs => _lastPersistedAtMs;
  Object? get restoreError => _restoreError;

  bool get hasValidLocation => NewReportFlowPolicy.hasValidLocation(_draft);
  bool get canSubmit => NewReportFlowPolicy.canSubmit(_draft);
  int get currentStageIndex =>
      NewReportFlowPolicy.currentStageIndex(_currentStage);

  void setSuppressLocalDraftPersist(bool value) {
    _suppressLocalDraftPersist = value;
  }

  Future<ReportDraftSummary> peekSavedDraft() => _draftRepo.summary();

  /// Seeds the camera/picker photo after the incoming-photo merge gate (or when no draft).
  Future<void> seedInitialPhotoFromPending() async {
    final XFile? incoming = _initialPhoto;
    if (incoming == null || _incomingPhotoMergeResolved) {
      return;
    }
    await _seedInitialPhoto(incoming);
    _markIncomingPhotoMergeResolved();
  }

  void _markIncomingPhotoMergeResolved() {
    _incomingPhotoMergeResolved = true;
    _suppressLocalDraftPersist = false;
    notifyListeners();
  }

  /// Resolves conflict between [initialPhoto] and an existing SQLite draft.
  Future<ReportDraftLoadResult?> resolveIncomingPhotoMerge(
    ResumeWithIncomingChoice choice,
  ) async {
    switch (choice) {
      case ResumeWithIncomingChoice.continueDraft:
        chistoReportsBreadcrumb('report_draft', 'incoming_photo_choice_continue');
        _markIncomingPhotoMergeResolved();
        return await restoreSavedDraft();
      case ResumeWithIncomingChoice.replaceDraft:
        chistoReportsBreadcrumb('report_draft', 'incoming_photo_choice_replace');
        final XFile incoming = _initialPhoto!;
        await discardDraft();
        await _seedInitialPhoto(incoming);
        _markIncomingPhotoMergeResolved();
        await persistWizardDraft(
          titleText: _draft.title,
          descriptionText: _draft.description,
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
    _restoreError = null;
    if (_initialPhoto != null && !_incomingPhotoMergeResolved) {
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
      _draft = saved.copyWith(title: title, description: description);
      if (snap.currentStageName != null && snap.currentStageName!.isNotEmpty) {
        try {
          _currentStage = ReportStage.values.byName(snap.currentStageName!);
        } catch (_) {
          _currentStage = ReportStage.evidence;
        }
      } else {
        _currentStage = ReportStage.evidence;
      }
      _attemptedStages.clear();
      for (final String name in snap.attemptedStageNames) {
        try {
          _attemptedStages.add(ReportStage.values.byName(name));
        } catch (_) {}
      }
      _lastPersistedAtMs = snap.lastPersistedAtMs ?? snap.updatedAtMs;
      notifyListeners();
      return r;
    } catch (e, st) {
      _restoreError = e;
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
    _hasSeenReportHelpHint = true;
    notifyListeners();
  }

  void clearDidAnnounceLocationStep() {
    _didAnnounceLocationStep = false;
  }

  void markLocationStepAnnounced() {
    _didAnnounceLocationStep = true;
    notifyListeners();
  }

  Future<void> loadReportingCapacity() async {
    try {
      final ReportCapacity capacity = await _reportsApi.getReportingCapacity();
      _reportCapacity = capacity;
      notifyListeners();
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
        current: _currentStage,
        draft: _draft,
      );

  void highlightStage(ReportStage stage) {
    _highlightTimer?.cancel();
    _highlightedStage = stage;
    notifyListeners();
    _highlightTimer = Timer(AppMotion.loadingOverlayLoop, () {
      if (_highlightedStage != stage) return;
      _highlightedStage = null;
      notifyListeners();
    });
  }

  void goToStage(ReportStage stage, {bool unfocusFirst = true}) {
    if (!canNavigateToStage(stage)) return;
    if (unfocusFirst) FocusManager.instance.primaryFocus?.unfocus();
    _currentStage = stage;
    _highlightedStage = null;
    if (stage != ReportStage.location) _didAnnounceLocationStep = false;
    notifyListeners();
  }

  bool canAdvanceFromCurrentStage() =>
      NewReportFlowPolicy.canAdvanceFromCurrentStage(
        current: _currentStage,
        draft: _draft,
      );

  void markStageAttempted(ReportStage stage) {
    _attemptedStages.add(stage);
    notifyListeners();
  }

  void setEvidenceTipDismissed(bool value) {
    _evidenceTipDismissed = value;
    notifyListeners();
  }

  void _setDraft(ReportDraft next) {
    _draft = next;
    notifyListeners();
  }

  void updateTitle(String value) =>
      _setDraft(_draft.copyWith(title: ReportInputSanitizer.clampTitle(value)));
  void updateDescription(String value) => _setDraft(
        _draft.copyWith(
          description: ReportInputSanitizer.clampDescription(value),
        ),
      );
  void updateSeverity(int severity) =>
      _setDraft(_draft.copyWith(severity: severity));
  void updateCategory(ReportCategory cat) =>
      _setDraft(_draft.copyWith(category: cat));
  void setCleanupEffort(CleanupEffort effort) =>
      _setDraft(_draft.copyWith(cleanupEffort: effort));

  void onLocationChanged(LocationPickerResult result) {
    if (!result.isInMacedonia) {
      _setDraft(_draft.copyWith(clearLocation: true));
      return;
    }
    final double lat = result.latitude;
    final double lng = result.longitude;
    if (!isReportLocationInMacedonia(lat, lng)) {
      _setDraft(_draft.copyWith(clearLocation: true));
      return;
    }
    _setDraft(
      _draft.copyWith(latitude: lat, longitude: lng, address: result.address),
    );
  }

  Future<void> addPhoto(XFile file) async {
    await _enqueuePhotoOp(() async {
      if (_draft.photos.length >= ReportFieldLimits.maxPhotos) {
        return;
      }
      final XFile managed = await _draftRepo.registerPhoto(file);
      _setDraft(_draft.copyWith(photos: <XFile>[..._draft.photos, managed]));
    });
  }

  Future<void> removePhoto(int index) async {
    await _enqueuePhotoOp(() async {
      final XFile removed = _draft.photos[index];
      await _draftRepo.deleteDraftPhoto(removed.path);
      final List<XFile> updated = List<XFile>.from(_draft.photos)..removeAt(index);
      _setDraft(_draft.copyWith(photos: updated));
    });
  }

  void setProcessingPhotoFlow(bool value) {
    _isProcessingPhotoFlow = value;
    notifyListeners();
  }

  void setApiError(AppError? e) {
    _apiError = e;
    notifyListeners();
  }

  void resetSubmittingUi() {
    _submitting = false;
    _submitPhase = null;
    notifyListeners();
  }

  void resetDraftAndStartOver() {
    _suppressLocalDraftPersist = false;
    _draft = ReportDraft();
    _currentStage = ReportStage.evidence;
    _highlightedStage = null;
    _attemptedStages.clear();
    _submitting = false;
    _submitPhase = null;
    _evidenceTipDismissed = false;
    _lastPersistedAtMs = null;
    notifyListeners();
  }

  void scheduleAutosave({
    required String titleText,
    required String descriptionText,
  }) {
    if (_suppressLocalDraftPersist || _submitting) return;
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
    if (_draft.hasPersistableWizardBody) {
      return true;
    }
    if (titleText.trim().isNotEmpty || descriptionText.trim().isNotEmpty) {
      return true;
    }
    if (_currentStage != ReportStage.evidence) {
      return true;
    }
    if (_attemptedStages.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> persistWizardDraft({
    required String titleText,
    required String descriptionText,
  }) async {
    if (_suppressLocalDraftPersist || _submitting) return;
    if (!_shouldPersistWizardDraft(titleText, descriptionText)) {
      return;
    }
    try {
      final int now = DateTime.now().millisecondsSinceEpoch;
      await _draftRepo.save(
        draft: _draft,
        title: titleText,
        description: descriptionText,
        currentStageName: _currentStage.name,
        attemptedStageNames: _attemptedStages.map((ReportStage e) => e.name).toList(),
        lastPersistedAtMs: now,
      );
      _lastPersistedAtMs = now;
      if (!_disposed) {
        notifyListeners();
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
    return !_suppressLocalDraftPersist &&
        !_submitting &&
        _shouldPersistWizardDraft(titleText, descriptionText);
  }

  void beginSubmitAttempt() {
    _attemptedStages.addAll(ReportStage.values);
    _apiError = null;
    notifyListeners();
  }

  void beginSubmittingPhase() {
    _submitting = true;
    _submitPhase = _draft.photos.isNotEmpty ? 'uploading' : 'creating';
    notifyListeners();
  }

  void markSubmitSentPhase() {
    _submitPhase = 'sent';
    notifyListeners();
  }

  Future<ReportSubmitResult> submitReport() {
    return _reportSubmitPort.submitReportAndAwait(
      draft: _draft,
      title: ReportInputSanitizer.clampTitle(_draft.title),
      description: ReportInputSanitizer.clampDescription(_draft.description),
    );
  }

  void endSubmitWithError(Object e) {
    _submitting = false;
    _submitPhase = null;
    _apiError = e is AppError
        ? e
        : e is TimeoutException
        ? AppError.timeout()
        : e is SocketException
        ? AppError.network(message: e.message, cause: e)
        : AppError.unknown(cause: e);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _highlightTimer?.cancel();
    _autosaveDebouncer.dispose();
    super.dispose();
  }
}
