import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/data/report_draft_storage.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_mock_store.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_grid.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_review_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_source_modal.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_category_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_widgets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/api_error_banner.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
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

class _NewReportScreenState extends State<NewReportScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();
  final int _maxDescriptionLength = 200;

  ReportDraft _draft = ReportDraft();
  bool _submitting = false;
  bool _isProcessingPhotoFlow = false;
  bool _evidenceTipDismissed = false;
  final Set<ReportStage> _attemptedStages = <ReportStage>{};
  ReportStage _currentStage = ReportStage.evidence;
  ReportStage? _highlightedStage;
  bool _didAnnounceLocationStep = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhoto != null) {
      _draft = _draft.copyWith(photos: <XFile>[widget.initialPhoto!]);
      _descriptionController.text = _draft.description;
    } else {
      _descriptionController.text = _draft.description;
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerRestoreDraft());
    }
  }

  Future<void> _offerRestoreDraft() async {
    if (!mounted) return;
    final ({ReportDraft draft, int stageIndex})? saved =
        await loadReportDraft();
    if (!mounted || saved == null) return;
    final bool? resume = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resume draft?'),
          content: const Text(
            'You have an unsaved report. Resume where you left off or start fresh.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Start fresh'),
            ),
            FilledButton(
              onPressed: () {
                AppHaptics.light();
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (resume == true) {
      setState(() {
        _draft = saved.draft;
        _currentStage =
            ReportStage.values[saved.stageIndex.clamp(0, ReportStage.values.length - 1)];
        _descriptionController.text = _draft.description;
      });
    }
    await clearReportDraft();
  }

  @override
  void deactivate() {
    _didAnnounceLocationStep = false;
    super.deactivate();
  }

  @override
  void dispose() {
    if (!_submitting) {
      saveReportDraft(
        draft: _draft,
        stageIndex: ReportStage.values.indexOf(_currentStage),
      );
    }
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    super.dispose();
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
              backgroundColor: AppColors.panelBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
              ),
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
  }

  void _setCleanupEffort(CleanupEffort effort) {
    AppHaptics.light();
    setState(() {
      _draft = _draft.copyWith(cleanupEffort: effort);
    });
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          'How many people do you think are needed to clean this up?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
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
      },
    );
  }

  bool _isStageComplete(ReportStage stage) {
    switch (stage) {
      case ReportStage.evidence:
        return _draft.hasPhotos;
      case ReportStage.details:
        return _draft.hasCategory;
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
      return _draft.hasPhotos && _draft.hasCategory;
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
        return _draft.hasCategory;
      case ReportStage.location:
        return _hasValidLocation;
      case ReportStage.review:
        return _canSubmit;
    }
  }

  String _stageBlockingMessage(ReportStage stage) {
    switch (stage) {
      case ReportStage.evidence:
        return 'Add at least one photo before continuing.';
      case ReportStage.details:
        return 'Choose a category before continuing.';
      case ReportStage.location:
        return 'Confirm a location inside Macedonia before continuing.';
      case ReportStage.review:
        return 'Finish the missing steps before submitting.';
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
      AppSnack.show(
        context,
        message: _stageBlockingMessage(_currentStage),
        type: AppSnackType.warning,
      );
      _highlightStage(_currentStage);
      return;
    }

    _goToStage(ReportStage.values[_currentStageIndex + 1]);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _attemptedStages.addAll(ReportStage.values);
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
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    ReportsListMockStore.addSubmittedDraft(_draft);
    await clearReportDraft();
    if (!mounted) return;
    setState(() => _submitting = false);
    final SubmittedDialogResult? result = await showDialog<SubmittedDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ReportSubmittedDialog(
          categoryLabel: _draft.category?.label ?? 'Report',
          address: _draft.address,
        );
      },
    );

    if (!mounted) return;
    if (result == SubmittedDialogResult.reportAnother) {
      _resetDraftAndStartOver();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _resetDraftAndStartOver() {
    setState(() {
      _draft = ReportDraft();
      _currentStage = ReportStage.evidence;
      _highlightedStage = null;
      _attemptedStages.clear();
      _submitting = false;
      _evidenceTipDismissed = false;
    });
    _descriptionController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
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
                  switchOutCurve: Curves.easeOutCubic,
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
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
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
          child: Text(
            widget.entryLabel ?? 'New report',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
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
                label: stage.shortLabel,
                isCurrent: stage == _currentStage,
                isComplete: _isStageComplete(stage),
                isEnabled: _canNavigateToStage(stage),
                onTap: () => _goToStage(stage),
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
            title: 'Evidence',
            message:
                'Start with one clear photo of the site. Add another only if it helps explain the issue.',
            contextHint: widget.entryHint,
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
            title: 'Details',
            message:
                'Pick the closest category, then add short context only if it helps moderation.',
            contextHint:
                'Keep this step short and factual. Moderators see this before the full report.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildCategoryField(context),
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
                'Location. Place the pin on the site, then confirm.',
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
            title: 'Location',
            message: 'Place the pin on the site, then confirm. Stays inside Macedonia.',
            contextHint:
                'Moderators rely on this spot to find the site. Take a moment to get it right.',
            child: LocationPicker(
              initialLatitude: _draft.latitude,
              initialLongitude: _draft.longitude,
              onLocationChanged: _onLocationChanged,
            ),
          ),
        );
      case ReportStage.review:
        return _buildStageScrollView(
          context,
          child: _buildStageSurface(
            context,
            stage: ReportStage.review,
            title: 'Review',
            message:
                'Check the essentials once, then send the report when it feels right.',
            contextHint:
                'Give everything one last look. You can still go back and adjust before you submit.',
            child: Column(
              children: <Widget>[
                ReviewSummaryTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Evidence',
                  subtitle: _draft.hasPhotos
                      ? '${_draft.photos.length} photo${_draft.photos.length == 1 ? '' : 's'} attached'
                      : 'Add at least one photo',
                  isComplete: _draft.hasPhotos,
                  onTap: () => _goToStage(ReportStage.evidence),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReviewSummaryTile(
                  icon: _draft.category?.icon ?? Icons.category_outlined,
                  title: 'Category',
                  subtitle: _draft.category?.label ?? 'Choose the issue type',
                  isComplete: _draft.hasCategory,
                  onTap: () => _goToStage(ReportStage.details),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReviewSummaryTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: _hasValidLocation
                      ? (_draft.address ?? 'Pinned location confirmed')
                      : 'Confirm the location in Macedonia',
                  isComplete: _hasValidLocation,
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
                    onTap: () => _goToStage(ReportStage.details),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ReportInfoBanner(
                  title: 'After you submit',
                  icon: Icons.verified_user_outlined,
                  tone: _canSubmit
                      ? ReportSurfaceTone.neutral
                      : ReportSurfaceTone.warning,
                  message: _canSubmit
                      ? 'The report will go to moderation first before it appears publicly.'
                      : 'Finish the missing essentials above before you submit.',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Moderators will review within a few days. You\'ll see the status in My reports.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
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
              message: _apiError!,
              onDismiss: () => setState(() => _apiError = null),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildStageSurface(
    BuildContext context, {
    required ReportStage stage,
    required String title,
    required String message,
    required Widget child,
    String? contextHint,
  }) {
    final bool isHighlighted = _highlightedStage == stage;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              ReportStatePill(
                label: stage.primaryRequirementLabel,
                tone: ReportSurfaceTone.accent,
              ),
              if (stage.secondaryRequirementLabel != null)
                ReportStatePill(label: stage.secondaryRequirementLabel!),
            ],
          ),
          if (contextHint != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              contextHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
          ],
          if (isHighlighted) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              label: _stageBlockingMessage(stage),
              child: const ReportInfoBanner(
                icon: Icons.error_outline_rounded,
                tone: ReportSurfaceTone.warning,
                message: 'This step needs attention before you continue.',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.divider.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
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
            title: _draft.category?.label ?? 'Select category',
            subtitle: _draft.category == null
                ? 'Choose the closest match.'
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
              'Short description (optional)',
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
          maxLength: _maxDescriptionLength,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String value) {
            setState(() {
              _draft = _draft.copyWith(description: value);
            });
          },
          textInputAction: TextInputAction.done,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: 'Describe the pollution site…',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: -0.2,
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Optional: add short context only if it helps explain the site.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bool showBack = _currentStage != ReportStage.evidence;
    final bool isReviewStage = _currentStage == ReportStage.review;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
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
                  label: isReviewStage ? 'Submit report' : 'Next: ${_currentStage.primaryActionLabel}',
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
                      child: Text(
                        _submitting
                            ? 'Submitting…'
                            : isReviewStage
                            ? 'Submit report'
                            : _currentStage.primaryActionLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isReviewStage
                  ? (_canSubmit
                      ? 'Ready to submit.'
                      : 'Finish the essentials before submitting.')
                  : _currentStage.footerHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
