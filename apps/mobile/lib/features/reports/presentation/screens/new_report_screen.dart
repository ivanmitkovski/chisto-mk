import 'dart:async';
import 'dart:io';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/data/report_flow_preferences.dart';
import 'package:chisto_mobile/features/reports/data/report_draft_storage.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_grid.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_review_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_source_modal.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_category_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_widgets.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final ReportFlowPreferences _reportFlowPreferences = const ReportFlowPreferences();
  bool _reportFlowPrefsLoaded = false;
  bool _hasSeenReportHelpHint = true;

  Timer? _draftSaveTimer;
  Timer? _draftSavedHideTimer;
  bool _showDraftSavedBanner = false;
  DateTime? _lastDraftSavedBannerShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reportFlowPreferences.hasSeenReportHelpHint.then((bool v) {
      if (!mounted) return;
      setState(() {
        _reportFlowPrefsLoaded = true;
        _hasSeenReportHelpHint = v;
      });
    });
    if (widget.initialPhoto != null) {
      _draft = _draft.copyWith(photos: <XFile>[widget.initialPhoto!]);
      _titleController.text = _draft.title;
      _descriptionController.text = _draft.description;
    } else {
      _titleController.text = _draft.title;
      _descriptionController.text = _draft.description;
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerRestoreDraft());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReportingCapacity());
  }

  Future<void> _offerRestoreDraft() async {
    if (!mounted) return;
    final ({ReportDraft draft, int stageIndex})? saved =
        await loadReportDraft();
    if (!mounted || saved == null) return;
    final bool? resume = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(dialogContext.l10n.resumeDraftTitle),
        content: Text(dialogContext.l10n.resumeDraftBody),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.resumeDraftStartFresh),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              AppHaptics.light();
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(dialogContext.l10n.resumeDraftResume),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      setState(() {
        _draft = saved.draft;
        _currentStage =
            ReportStage.values[saved.stageIndex.clamp(0, ReportStage.values.length - 1)];
        _titleController.text = _draft.title;
        _descriptionController.text = _draft.description;
      });
      unawaited(_saveDraftImmediately());
    }
    await clearReportDraft();
  }

  Future<void> _dismissFlowHelpHint() async {
    AppHaptics.light();
    await _reportFlowPreferences.setSeenReportHelpHint();
    if (mounted) setState(() => _hasSeenReportHelpHint = true);
  }

  Future<void> _onFlowHelpOpened() async {
    await _reportFlowPreferences.setSeenReportHelpHint();
    if (mounted) setState(() => _hasSeenReportHelpHint = true);
  }

  @override
  void deactivate() {
    _didAnnounceLocationStep = false;
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _draftSaveTimer?.cancel();
      unawaited(_saveDraftImmediately());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveTimer?.cancel();
    _draftSavedHideTimer?.cancel();
    if (!_submitting) {
      saveReportDraft(
        draft: _draft,
        stageIndex: ReportStage.values.indexOf(_currentStage),
      );
    }
    _titleController.dispose();
    _titleFocus.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
    if (_submitting) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _submitting) return;
      saveReportDraft(
        draft: _draft,
        stageIndex: ReportStage.values.indexOf(_currentStage),
      ).then((_) {
        if (!mounted) return;
        _maybeShowDraftSavedBanner();
      });
    });
  }

  void _maybeShowDraftSavedBanner() {
    final DateTime now = DateTime.now();
    if (_lastDraftSavedBannerShown != null &&
        now.difference(_lastDraftSavedBannerShown!) <
            const Duration(seconds: 60)) {
      return;
    }
    _lastDraftSavedBannerShown = now;
    _draftSavedHideTimer?.cancel();
    setState(() => _showDraftSavedBanner = true);
    _draftSavedHideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showDraftSavedBanner = false);
    });
  }

  Future<void> _saveDraftImmediately() async {
    _draftSaveTimer?.cancel();
    if (_submitting) return;
    await saveReportDraft(
      draft: _draft,
      stageIndex: ReportStage.values.indexOf(_currentStage),
    );
  }

  bool get _hasValidLocation {
    final double? lat = _draft.latitude;
    final double? lng = _draft.longitude;
    return lat != null && lng != null && isReportLocationInMacedonia(lat, lng);
  }

  bool get _canSubmit => _draft.isValid && _hasValidLocation;

  int get _currentStageIndex => ReportStage.values.indexOf(_currentStage);

  Future<void> _addPhoto() async {
    if (_draft.photos.length >= 5 || _isProcessingPhotoFlow) return;

    AppHaptics.tap();
    final ImageSource? source = await showPhotoSourceModal(context);
    if (source == null || !mounted) return;
    await _pickAndReview(source);
  }

  Future<void> _pickAndReview(ImageSource source) async {
    if (_isProcessingPhotoFlow) return;

    setState(() {
      _isProcessingPhotoFlow = true;
    });

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
              message:
                  'Unable to open the camera right now. Please try again in a moment.',
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
          final bool wasEmpty = _draft.photos.isEmpty;
          setState(() {
            _draft = _draft.copyWith(
              photos: <XFile>[..._draft.photos, selectedFile],
            );
          });
          _scheduleDraftSave();
          if (wasEmpty) {
            AppHaptics.success();
          }
        }
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPhotoFlow = false;
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      final List<XFile> updated = List<XFile>.from(_draft.photos)
        ..removeAt(index);
      _draft = _draft.copyWith(photos: updated);
    });
    _scheduleDraftSave();
  }

  void _setCleanupEffort(CleanupEffort effort) {
    AppHaptics.light();
    setState(() {
      _draft = _draft.copyWith(cleanupEffort: effort);
    });
    _scheduleDraftSave();
  }

  void _onLocationChanged(LocationPickerResult result) {
    if (!mounted) return;
    setState(() {
      if (!result.isInMacedonia) {
        _draft = _draft.copyWith(clearLocation: true);
        return;
      }
      final double lat = result.latitude;
      final double lng = result.longitude;
      if (!isReportLocationInMacedonia(lat, lng)) {
        _draft = _draft.copyWith(clearLocation: true);
        return;
      }
      _draft = _draft.copyWith(
        latitude: lat,
        longitude: lng,
        address: result.address,
      );
    });
    _scheduleDraftSave();
  }

  Widget _buildCleanupEffortField(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        );
    final CleanupEffort? current = _draft.cleanupEffort;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Cleanup effort', style: labelStyle),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: CleanupEffort.values.map((CleanupEffort effort) {
            final bool selected = current == effort;
            return Semantics(
              button: true,
              label: effort.label,
              hint: 'Double-tap to set estimated cleanup effort.',
              child: ChoiceChip(
                label: Text(effort.label),
                selected: selected,
                onSelected: (_) => _setCleanupEffort(effort),
                selectedColor: AppColors.primary.withValues(alpha: 0.14),
                labelStyle: AppTypography.badgeLabel.copyWith(
                  color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.inputFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primaryDark.withValues(alpha: 0.5)
                        : AppColors.divider.withValues(alpha: 0.9),
                    width: 0.9,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _openCategoryPicker() {
    showReportCategoryPicker(
      context,
      selected: _draft.category,
      onSelected: (ReportCategory cat) {
        setState(() => _draft = _draft.copyWith(category: cat));
        _scheduleDraftSave();
      },
    );
  }

  bool _isStageComplete(ReportStage stage) {
    switch (stage) {
      case ReportStage.evidence:
        return _draft.hasPhotos;
      case ReportStage.details:
        return _draft.hasCategory && _draft.hasTitle;
      case ReportStage.location:
        return _hasValidLocation;
      case ReportStage.review:
        return _canSubmit;
    }
  }

  bool _canNavigateToStage(ReportStage stage) {
    final int targetIndex = ReportStage.values.indexOf(stage);
    if (targetIndex <= _currentStageIndex) {
      return true;
    }
    if (stage == ReportStage.details) {
      return _draft.hasPhotos;
    }
    if (stage == ReportStage.location) {
      return _draft.hasPhotos && _draft.hasCategory && _draft.hasTitle;
    }
    return _canSubmit;
  }

  void _highlightStage(ReportStage stage) {
    setState(() => _highlightedStage = stage);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _highlightedStage != stage) return;
      setState(() => _highlightedStage = null);
    });
  }

  void _goToStage(ReportStage stage, {bool withHaptic = true}) {
    if (!_canNavigateToStage(stage)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (withHaptic) {
      AppHaptics.light();
    }
    setState(() {
      _currentStage = stage;
      _highlightedStage = null;
      if (stage != ReportStage.location) {
        _didAnnounceLocationStep = false;
      }
    });
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
    if (!_draft.hasPhotos) {
      _goToStage(ReportStage.evidence, withHaptic: false);
      _highlightStage(ReportStage.evidence);
      return;
    }
    if (!_draft.hasCategory) {
      _goToStage(ReportStage.details, withHaptic: false);
      _highlightStage(ReportStage.details);
      return;
    }
    if (!_draft.hasTitle) {
      _goToStage(ReportStage.details, withHaptic: false);
      _highlightStage(ReportStage.details);
      return;
    }
    if (!_hasValidLocation) {
      _goToStage(ReportStage.location, withHaptic: false);
      _highlightStage(ReportStage.location);
      return;
    }
  }

  bool _canAdvanceFromCurrentStage() {
    switch (_currentStage) {
      case ReportStage.evidence:
        return _draft.hasPhotos;
      case ReportStage.details:
        return _draft.hasCategory && _draft.hasTitle;
      case ReportStage.location:
        return _hasValidLocation;
      case ReportStage.review:
        return _canSubmit;
    }
  }

  void _handlePrimaryAction() {
    if (_currentStage == ReportStage.review) {
      _submit();
      return;
    }

    if (!_canAdvanceFromCurrentStage()) {
      setState(() {
        _attemptedStages.add(_currentStage);
      });
      _highlightStage(_currentStage);
      return;
    }

    _goToStage(ReportStage.values[_currentStageIndex + 1], withHaptic: false);
    if (!MediaQuery.disableAnimationsOf(context)) {
      AppHaptics.settle();
    }
  }

  Future<void> _loadReportingCapacity() async {
    try {
      final ReportCapacity capacity =
          await ServiceLocator.instance.reportsApiRepository.getReportingCapacity();
      if (!mounted) return;
      setState(() => _reportCapacity = capacity);
    } catch (_) {
      // Non-blocking UI hint only; submit endpoint remains authoritative.
    }
  }

  ReportCapacity? _capacityFromErrorDetails(dynamic details) {
    if (details is! Map<String, dynamic>) return null;
    final int creditsAvailable = (details['creditsAvailable'] as num?)?.toInt() ?? 0;
    final bool emergencyAvailable = details['emergencyAvailable'] as bool? ?? false;
    final int? retryAfterSeconds = (details['retryAfterSeconds'] as num?)?.toInt();
    final String unlockHint = details['unlockHint'] as String? ??
        'Join and verify attendance, or create an eco action to unlock more reports.';
    return ReportCapacity(
      creditsAvailable: creditsAvailable,
      emergencyAvailable: emergencyAvailable,
      emergencyWindowDays: 7,
      retryAfterSeconds: retryAfterSeconds,
      unlockHint: unlockHint,
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _attemptedStages.addAll(ReportStage.values);
      _apiError = null;
    });

    if (!_canSubmit) {
      AppSnack.show(
        context,
        message: 'Please finish the missing steps before submitting.',
        type: AppSnackType.warning,
      );
      _goToFirstInvalidStage();
      return;
    }

    AppHaptics.medium();
    setState(() {
      _submitting = true;
      _submitPhase = 'creating';
    });

    try {
      final reportsApi = ServiceLocator.instance.reportsApiRepository;
      final String trimmedTitle = _draft.title.trim();
      final String trimmedDescription = _draft.description.trim();
      final result = await reportsApi.submitReport(
        latitude: _draft.latitude!,
        longitude: _draft.longitude!,
        title: trimmedTitle,
        description: trimmedDescription.isNotEmpty ? trimmedDescription : null,
        mediaUrls: null,
        category: _draft.category?.apiString,
        severity: _draft.severity,
        address: _draft.address?.trim().isNotEmpty == true ? _draft.address!.trim() : null,
        cleanupEffort: _draft.cleanupEffort?.apiKey,
      );
      if (!mounted) return;
      if (_draft.photos.isNotEmpty) {
        setState(() => _submitPhase = 'uploading');
        if (!mounted) return;
        final List<String> paths =
            _draft.photos.map<String>((XFile x) => x.path).toList();
        bool uploadSuccess = false;
        try {
          await reportsApi.uploadReportMedia(result.reportId, paths);
          uploadSuccess = true;
        } catch (e) {
          if (!mounted) return;
          final bool? retry = await showCupertinoDialog<bool>(
            context: context,
            builder: (BuildContext ctx) => CupertinoAlertDialog(
              title: const Text('Photo upload failed'),
              content: const Text(
                'Report was submitted. Tap Retry to upload your photos, or Skip to continue.',
              ),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Skip'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (retry == true) {
            try {
              await reportsApi.uploadReportMedia(result.reportId, paths);
              uploadSuccess = true;
            } catch (_) {}
          }
        }
        if (!uploadSuccess && mounted) {
          AppSnack.show(
            context,
            message: 'Report submitted. Photos could not be uploaded.',
            type: AppSnackType.warning,
          );
        }
      }
      if (!mounted) return;
      await clearReportDraft();
      if (!mounted) return;
      ServiceLocator.instance.profileNeedsRefresh.value++;
      setState(() {
        _submitting = false;
        _submitPhase = null;
      });
      final Object? dialogResult = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ReportSubmittedDialog(
            categoryLabel: _draft.category?.label ?? 'Report',
            reportNumber: result.reportNumber,
            reportId: result.reportId,
            address: _draft.address,
            pointsAwarded: result.pointsAwarded,
            isNewSite: result.isNewSite,
          );
        },
      );
      if (!mounted) return;
      if (dialogResult == SubmittedDialogResult.reportAnother) {
        _resetDraftAndStartOver();
      } else {
        Navigator.of(context).pop(dialogResult is String ? dialogResult : true);
      }
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitPhase = null;
      });
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'ACCOUNT_NOT_ACTIVE') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return;
      }
      if (e.code == 'REPORTING_COOLDOWN') {
        final capacity = _capacityFromErrorDetails(e.details);
        if (capacity != null) {
          await showReportingCooldownDialog(context, capacity);
          await _loadReportingCapacity();
          return;
        }
      }
      setState(() => _apiError = e);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitPhase = null;
        _apiError = e is TimeoutException
            ? AppError.timeout()
            : e is SocketException
                ? AppError.network(message: e.message, cause: e)
                : AppError.unknown(cause: e);
      });
    }
  }

  void _resetDraftAndStartOver() {
    setState(() {
      _draft = ReportDraft();
      _currentStage = ReportStage.evidence;
      _highlightedStage = null;
      _attemptedStages.clear();
      _submitting = false;
      _submitPhase = null;
      _evidenceTipDismissed = false;
    });
    _titleController.text = '';
    _descriptionController.text = '';
    _scheduleDraftSave();
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildTopBar(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildStageStepper(context),
                  ],
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
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                  child: KeyedSubtree(
                    key: ValueKey<ReportStage>(_currentStage),
                    child: _buildCurrentStage(context),
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
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportCircleIconButton(
          icon: Icons.chevron_left_rounded,
          semanticLabel: _currentStage == ReportStage.evidence
              ? 'Back'
              : 'Previous step',
          onTap: () {
            if (_currentStage == ReportStage.evidence) {
              Navigator.of(context).maybePop();
              return;
            }
            _goToStage(ReportStage.values[_currentStageIndex - 1]);
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.entryLabel ?? context.l10n.newReportTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (_showDraftSavedBanner) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  context.l10n.reportDraftSaved,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        ReportStatePill(
          label: '${_currentStageIndex + 1}/${ReportStage.values.length}',
          tone: _currentStage == ReportStage.review
              ? ReportSurfaceTone.success
              : ReportSurfaceTone.neutral,
        ),
      ],
    );
  }

  Widget _buildStageStepper(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Row(
          children: ReportStage.values.asMap().entries.map((
            MapEntry<int, ReportStage> entry,
          ) {
            final ReportStage stage = entry.value;
            return Expanded(
              child: StageChip(
                label: stage.config(context.l10n).shortLabel,
                isCurrent: stage == _currentStage,
                isComplete: _isStageComplete(stage),
                isEnabled: _canNavigateToStage(stage),
                onTap: () => _goToStage(stage),
                stepIndex: entry.key,
                totalSteps: ReportStage.values.length,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentStage(BuildContext context) {
    switch (_currentStage) {
      case ReportStage.evidence:
        return _buildStageScrollView(
          context,
          child: _buildStageSurface(
            context,
            stage: ReportStage.evidence,
            infoExtra: widget.entryHint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_draft.photos.isEmpty && !_evidenceTipDismissed)
                  EvidenceTipCard(
                    onDismiss: () {
                      AppHaptics.light();
                      setState(() => _evidenceTipDismissed = true);
                    },
                  ),
                if (_draft.photos.isEmpty && !_evidenceTipDismissed)
                  const SizedBox(height: AppSpacing.md),
                PhotoGrid(
                  photos: _draft.photos,
                  onAddPhoto: _addPhoto,
                  onRemovePhoto: _removePhoto,
                ),
                if (_attemptedStages.contains(ReportStage.evidence) &&
                    !_draft.hasPhotos) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.reportFlowEvidenceNeedsPhoto,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accentDanger,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case ReportStage.details:
        return _buildStageScrollView(
          context,
          child: _buildStageSurface(
            context,
            stage: ReportStage.details,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildCategoryField(context),
                const SizedBox(height: AppSpacing.md),
                _buildSeverityField(context),
                const SizedBox(height: AppSpacing.md),
                _buildTitleField(context),
                const SizedBox(height: AppSpacing.md),
                _buildDescriptionField(context),
                const SizedBox(height: AppSpacing.md),
                _buildCleanupEffortField(context),
              ],
            ),
          ),
        );
      case ReportStage.location:
        if (!_hasValidLocation && !_didAnnounceLocationStep) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (MediaQuery.supportsAnnounceOf(context)) {
              SemanticsService.sendAnnouncement(
                View.of(context),
                'Location: pin, then confirm.',
                Directionality.of(context),
              );
            }
            setState(() => _didAnnounceLocationStep = true);
          });
        }
        return _buildStageScrollView(
          context,
          child: _buildStageSurface(
            context,
            stage: ReportStage.location,
            child: LocationPicker(
              initialLatitude: _draft.latitude,
              initialLongitude: _draft.longitude,
              onLocationChanged: _onLocationChanged,
              showAdvanceBlockedHint:
                  _attemptedStages.contains(ReportStage.location) &&
                  !_hasValidLocation,
            ),
          ),
        );
      case ReportStage.review:
        return _buildStageScrollView(
          context,
          child: _buildStageSurface(
            context,
            stage: ReportStage.review,
            child: Column(
              children: <Widget>[
                ReviewSummaryTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Evidence',
                  subtitle: _draft.hasPhotos
                      ? '${_draft.photos.length} photo${_draft.photos.length == 1 ? '' : 's'}'
                      : 'Add a photo',
                  isComplete: _draft.hasPhotos,
                  semanticsHint: context.l10n.reviewTapToEdit,
                  onTap: () => _goToStage(ReportStage.evidence),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReviewSummaryTile(
                  icon: _draft.category?.icon ?? Icons.category_outlined,
                  title: 'Category',
                  subtitle: _draft.category?.label ?? 'Choose category',
                  isComplete: _draft.hasCategory,
                  semanticsHint: context.l10n.reviewTapToEdit,
                  onTap: () => _goToStage(ReportStage.details),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReviewSummaryTile(
                  icon: Icons.title_rounded,
                  title: 'Title',
                  subtitle: _draft.hasTitle
                      ? _draft.title.trim()
                      : 'Add title',
                  isComplete: _draft.hasTitle,
                  semanticsHint: context.l10n.reviewTapToEdit,
                  onTap: () => _goToStage(ReportStage.details),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReviewSummaryTile(
                  icon: Icons.signal_cellular_alt,
                  title: 'Severity',
                  subtitle: _severityLabel(_draft.severity),
                  isComplete: true,
                  isOptional: true,
                  semanticsHint: context.l10n.reviewTapToEdit,
                  onTap: () => _goToStage(ReportStage.details),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReviewSummaryTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: _hasValidLocation
                      ? (_draft.address ?? 'Pinned')
                      : 'Pin in Macedonia',
                  isComplete: _hasValidLocation,
                  semanticsHint: context.l10n.reviewTapToEdit,
                  onTap: () => _goToStage(ReportStage.location),
                ),
                if (_draft.hasDescription) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  ReviewSummaryTile(
                    icon: Icons.notes_outlined,
                    title: 'Extra context',
                    subtitle: _draft.description.trim(),
                    isComplete: true,
                    isOptional: true,
                    semanticsHint: context.l10n.reviewTapToEdit,
                    onTap: () => _goToStage(ReportStage.details),
                  ),
                ],
                if (_draft.cleanupEffort != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  ReviewSummaryTile(
                    icon: Icons.group_outlined,
                    title: 'Cleanup effort',
                    subtitle: _draft.cleanupEffort!.label,
                    isComplete: true,
                    isOptional: true,
                    semanticsHint: context.l10n.reviewTapToEdit,
                    onTap: () => _goToStage(ReportStage.details),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ReportInfoBanner(
                  title: context.l10n.reportReviewBannerAfterSubmitTitle,
                  icon: Icons.verified_user_outlined,
                  tone: _canSubmit
                      ? ReportSurfaceTone.neutral
                      : ReportSurfaceTone.warning,
                  message: _canSubmit
                      ? context.l10n.reportReviewAfterSubmitReady
                      : context.l10n.reportReviewAfterSubmitIncomplete,
                ),
                if (_reportCapacity != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (BuildContext context) {
                      final ReportCapacityUiState ui =
                          mapReportCapacityToUiState(_reportCapacity!);
                      return ReportInfoBanner(
                        title: context.l10n.reportReviewBannerCreditsTitle,
                        emphasis: ReportInfoBannerEmphasis.secondary,
                        icon: ui.pillIcon,
                        tone: ui.pillTone,
                        message: ui.reviewMessage,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  Widget _buildStageScrollView(BuildContext context, {required Widget child}) {
    return SingleChildScrollView(
      key: PageStorageKey<ReportStage>(_currentStage),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_apiError != null) ...[
            ApiErrorBanner(
              message: _apiError!.message,
              onDismiss: () => setState(() => _apiError = null),
              onRetry: _apiError!.retryable
                  ? () {
                      setState(() => _apiError = null);
                      _submit();
                    }
                  : null,
              detail: _apiError!.retryable
                  ? context.l10n.errorBannerDraftSavedHint
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }

  Future<void> _showStageHelpModal(
    BuildContext context,
    ReportStage stage, {
    String? infoExtra,
  }) async {
    AppHaptics.light();
    await _onFlowHelpOpened();
    if (!context.mounted) return;
    final String trimmed = infoExtra?.trim() ?? '';
    final String barrierLabel =
        MaterialLocalizations.of(context).modalBarrierDismissLabel;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: AppColors.transparent,
      elevation: 0,
      barrierLabel: barrierLabel,
      builder: (BuildContext sheetContext) {
        final ReportStageConfig cfg = stage.config(sheetContext.l10n);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: MediaQuery.sizeOf(sheetContext).width,
              child: ReportSheetScaffold(
                fitToContent: true,
                addBottomInset: true,
                maxHeightFactor: 0.92,
                headerDividerGap: AppSpacing.sm,
                title: cfg.infoTitle,
                subtitle: cfg.subtitle,
                trailing: ReportCircleIconButton(
                  icon: Icons.close_rounded,
                  semanticLabel: sheetContext.l10n.semanticsClose,
                  onTap: () {
                    AppHaptics.tap();
                    Navigator.of(sheetContext).pop();
                  },
                ),
                child: StageHelpFormattedContent(
                  sections: cfg.helpSections,
                  contextSectionTitle: sheetContext.l10n.reportHelpContextTitle,
                  extraParagraph: trimmed.isEmpty ? null : trimmed,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageSurface(
    BuildContext context, {
    required ReportStage stage,
    required Widget child,
    String? infoExtra,
  }) {
    final bool isHighlighted = _highlightedStage == stage;
    final ReportStageConfig cfg = stage.config(context.l10n);

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isHighlighted
              ? AppColors.accentDanger.withValues(alpha: 0.32)
              : AppColors.divider.withValues(alpha: 0.7),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  cfg.infoTitle,
                  style: AppTypography.sectionHeader,
                ),
              ),
              Semantics(
                button: true,
                label: context.l10n.semanticsAboutStep(cfg.infoTitle),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.info_outline_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'About this step',
                  onPressed: () =>
                      _showStageHelpModal(context, stage, infoExtra: infoExtra),
                ),
              ),
            ],
          ),
          if (_reportFlowPrefsLoaded &&
              !_hasSeenReportHelpHint &&
              stage == ReportStage.evidence) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.reportFlowHelpHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textMuted,
                  tooltip: 'Dismiss',
                  onPressed: _dismissFlowHelpHint,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Divider(color: AppColors.divider.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  static const List<String> _severityLabels = <String>[
    'Low',
    'Moderate',
    'Significant',
    'High',
    'Critical',
  ];

  String _severityLabel(int value) =>
      '${value.clamp(1, 5)} – ${_severityLabels[(value.clamp(1, 5) - 1)]}';

  /// Keeps focused fields scrollable above the IME and bottom CTA bar.
  EdgeInsets _detailsFieldScrollPadding(BuildContext context) {
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.only(bottom: safeBottom + kBottomNavigationBarHeight + 20);
  }

  Widget _buildSeverityField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Severity',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: AppColors.inputBorder.withValues(alpha: 0.8),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _severityLabel(_draft.severity),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CupertinoSlider(
                value: _draft.severity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: AppColors.primary,
                onChanged: (double value) {
                  AppHaptics.light();
                  setState(
                    () => _draft = _draft.copyWith(
                      severity: value.round().clamp(1, 5),
                    ),
                  );
                  _scheduleDraftSave();
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Low',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Critical',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    final bool hasTitleError =
        _attemptedStages.contains(ReportStage.details) && !_draft.hasTitle;
    final int length = _titleController.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              'Title',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasTitleError
                    ? AppColors.accentDanger
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            Text(
              '$length/$_maxTitleLength',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _titleController,
          focusNode: _titleFocus,
          scrollPadding: _detailsFieldScrollPadding(context),
          maxLength: _maxTitleLength,
          maxLines: 1,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String value) {
            setState(() {
              _draft = _draft.copyWith(title: value);
            });
            _scheduleDraftSave();
          },
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: 'Brief headline',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.15,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            counterText: '',
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: hasTitleError ? AppColors.accentDanger : AppColors.divider,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    final bool hasCategoryError =
        _attemptedStages.contains(ReportStage.details) && !_draft.hasCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Category',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: hasCategoryError
                ? AppColors.accentDanger
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Select report category',
          value: _draft.category?.label,
          child: ReportActionTile(
            icon: _draft.category?.icon ?? Icons.category_outlined,
            title: _draft.category?.label ?? 'Category',
            subtitle: _draft.category == null
                ? 'Choose'
                : _draft.category!.description,
            tone: hasCategoryError
                ? ReportSurfaceTone.danger
                : ReportSurfaceTone.neutral,
            trailing: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
            onTap: _openCategoryPicker,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    final int length = _descriptionController.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              'Details',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            Text(
              '$length/$_maxDescriptionLength',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          scrollPadding: _detailsFieldScrollPadding(context),
          maxLength: _maxDescriptionLength,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String value) {
            setState(() {
              _draft = _draft.copyWith(description: value);
            });
            _scheduleDraftSave();
          },
          textInputAction: TextInputAction.done,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: 'Anything else',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.15,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            counterText: '',
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bool showBack = _currentStage != ReportStage.evidence;
    final bool isReviewStage = _currentStage == ReportStage.review;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (showBack) ...<Widget>[
            Expanded(
              child: Semantics(
                button: true,
                label: 'Back',
                hint: 'Double-tap to go to previous step.',
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => _goToStage(
                            ReportStage.values[_currentStageIndex - 1],
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                    backgroundColor: AppColors.panelBackground,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius18),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            flex: showBack ? 2 : 1,
            child: Semantics(
              button: true,
              label: isReviewStage
                  ? 'Submit report'
                  : context.l10n.semanticsNextStep(
                      _currentStage.config(context.l10n).shortLabel,
                    ),
              hint: isReviewStage ? 'Double-tap to submit' : 'Double-tap to go to next step.',
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _handlePrimaryAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.42,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius18),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _submitting
                          ? (_submitPhase == 'creating'
                              ? 'Creating…'
                              : _submitPhase == 'uploading'
                                  ? 'Uploading…'
                                  : 'Submitting…')
                          : _currentStage.config(context.l10n).primaryActionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
