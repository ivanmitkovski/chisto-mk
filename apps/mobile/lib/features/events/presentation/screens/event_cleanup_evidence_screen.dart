import 'dart:io';

// Upload/save UX: mirrors create-event and chat flows — explicit busy state on the
// primary action, [AppSnack] for recoverable errors, no separate async card (see
// [EventsAsyncSection] on detail for list-style retry surfaces).

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/cleanup_evidence/cleanup_evidence_save_result_dialog.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/cleanup_evidence/cleanup_evidence_widgets.dart';
import 'package:chisto_mobile/features/reports/data/report_photo_upload_prep.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

class EventCleanupEvidenceScreen extends StatefulWidget {
  const EventCleanupEvidenceScreen({
    super.key,
    required this.eventId,
    @visibleForTesting this.testPickAfterImagePathsOverride,
    @visibleForTesting this.testSetAfterImagesOverride,
  });

  final String eventId;

  /// Skips gallery + file copy; supplies local paths (widget tests).
  final Future<List<String>> Function()? testPickAfterImagePathsOverride;

  /// Replaces [EventsRepository.setAfterImages] (widget tests: errors / retries).
  final Future<bool> Function({
    required String eventId,
    required List<String> imagePaths,
  })? testSetAfterImagesOverride;

  @override
  State<EventCleanupEvidenceScreen> createState() =>
      _EventCleanupEvidenceScreenState();
}

class _EventCleanupEvidenceScreenState
    extends State<EventCleanupEvidenceScreen> {
  static const int _maxAfterImages = 8;
  static const double _heroHeight = 260;
  static const double _thumbSize = 64;
  static const double _thumbStripHeight = 74;

  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
  ImagePicker? _imagePicker;
  ImagePicker get _picker => _imagePicker ??= ImagePicker();
  final ValueNotifier<String> _tab = ValueNotifier<String>('after');

  List<String> _afterImages = <String>[];
  int _selectedIndex = 0;
  bool _isPicking = false;
  bool _isSaving = false;

  EcoEvent? get _event => _eventsRepository.findById(widget.eventId);

  @override
  void initState() {
    super.initState();
    _eventsRepository.loadInitialIfNeeded();
    _eventsRepository.addListener(_onRepoChanged);
    _afterImages =
        List<String>.from(_event?.afterImagePaths ?? const <String>[]);
  }

  @override
  void dispose() {
    _eventsRepository.removeListener(_onRepoChanged);
    _tab.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    void apply() {
      if (!mounted) return;
      setState(() {});
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
      return;
    }
    apply();
  }

  Future<void> _pickAfterImages() async {
    final int remaining = _maxAfterImages - _afterImages.length;
    if (remaining <= 0) {
      AppSnack.show(
        context,
        message: context.l10n.eventsEvidenceMaxPhotosSnack(_maxAfterImages),
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _isPicking = true);

    try {
      if (widget.testPickAfterImagePathsOverride != null) {
        final List<String> picked =
            await widget.testPickAfterImagePathsOverride!();
        if (!mounted) {
          return;
        }
        if (picked.isEmpty) {
          setState(() => _isPicking = false);
          return;
        }
        final List<String> next = List<String>.from(_afterImages);
        for (final String path in picked) {
          if (next.length >= _maxAfterImages) {
            break;
          }
          if (path.trim().isNotEmpty && !next.contains(path)) {
            next.add(path);
          }
        }
        setState(() {
          _afterImages = next;
          _selectedIndex = _selectedIndex.clamp(0, _afterImages.length - 1);
          _isPicking = false;
        });
        return;
      }

      final List<XFile> picked =
          await _picker.pickMultiImage(imageQuality: 86);
      if (picked.isEmpty || !mounted) {
        if (mounted) setState(() => _isPicking = false);
        return;
      }

      final List<String> prepared =
          await prepareReportPhotoPathsForUpload(picked);
      if (!mounted) {
        deleteReportUploadTempFiles(prepared);
        return;
      }

      final List<String> next = List<String>.from(_afterImages);
      for (final String saved in prepared) {
        if (next.length >= _maxAfterImages) break;
        if (saved.trim().isNotEmpty && !next.contains(saved)) {
          next.add(saved);
        }
      }
      if (!mounted) return;
      setState(() {
        _afterImages = next;
        _selectedIndex = _selectedIndex.clamp(0, _afterImages.length - 1);
        _isPicking = false;
      });
    } on Object catch (_) {
      if (!mounted) return;
      logEventsDiagnostic('cleanup_evidence_pick_failed');
      setState(() => _isPicking = false);
      AppSnack.show(
        context,
        message: context.l10n.eventsEvidencePickFailedSnack,
        type: AppSnackType.error,
      );
    }
  }

  void _openFullscreenGallery(int initialIndex) {
    AppHaptics.softTransition();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => CleanupFullscreenGalleryPage(
          imagePaths: _afterImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _removeAfterImage(int index) {
    if (index < 0 || index >= _afterImages.length) return;
    setState(() {
      _afterImages.removeAt(index);
      if (_afterImages.isEmpty) {
        _selectedIndex = 0;
      } else if (_selectedIndex >= _afterImages.length) {
        _selectedIndex = _afterImages.length - 1;
      }
    });
  }

  void _setAsCover(int index) {
    if (index < 0 || index >= _afterImages.length) return;
    if (index == 0) return;
    setState(() {
      final String path = _afterImages.removeAt(index);
      _afterImages.insert(0, path);
      _selectedIndex = 0;
    });
  }

  void _showThumbnailContextMenu(int index) {
    AppHaptics.softTransition();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext sheetCtx) {
        final l10n = sheetCtx.l10n;
        return ReportSheetScaffold(
          title: l10n.eventsEvidenceThumbnailMenuTitle,
          fitToContent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ReportActionTile(
                icon: CupertinoIcons.star,
                title: l10n.eventsSetCover,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _setAsCover(index);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportActionTile(
                icon: CupertinoIcons.eye,
                title: l10n.eventsViewFullscreen,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openFullscreenGallery(index);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportActionTile(
                icon: CupertinoIcons.trash,
                title: l10n.eventsEvidenceRemoveAction,
                tone: ReportSurfaceTone.danger,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _removeAfterImage(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final EcoEvent? event = _event;
    if (event == null) return;

    setState(() => _isSaving = true);
    bool changed = false;
    try {
      changed = widget.testSetAfterImagesOverride != null
          ? await widget.testSetAfterImagesOverride!(
              eventId: event.id,
              imagePaths: _afterImages,
            )
          : await _eventsRepository.setAfterImages(
              eventId: event.id,
              imagePaths: _afterImages,
            );
    } on AppError catch (e) {
      if (!mounted) return;
      logEventsDiagnostic('cleanup_evidence_save_failed');
      setState(() => _isSaving = false);
      final String detail = e.message.isNotEmpty
          ? e.message
          : context.l10n.eventsMutationFailedGeneric;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: AppColors.overlay,
        builder: (BuildContext ctx) => CleanupEvidenceSaveResultDialog(
          outcome: CleanupEvidenceSaveOutcome.failure,
          failureDetail: detail,
        ),
      );
      return;
    } on Object {
      if (!mounted) return;
      logEventsDiagnostic('cleanup_evidence_save_failed');
      setState(() => _isSaving = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: AppColors.overlay,
        builder: (BuildContext ctx) => CleanupEvidenceSaveResultDialog(
          outcome: CleanupEvidenceSaveOutcome.failure,
          failureDetail: context.l10n.eventsMutationFailedGeneric,
        ),
      );
      return;
    }
    if (!mounted) return;

    // Server replaces locals with signed URLs; without syncing, [hasPendingChanges]
    // stays true vs [event.afterImagePaths] and [PopScope] blocks [Navigator.pop].
    final List<String> pathsBeforeSync = List<String>.from(_afterImages);
    setState(() {
      _isSaving = false;
      if (changed) {
        final EcoEvent? fresh = _event;
        if (fresh != null) {
          _afterImages = List<String>.from(fresh.afterImagePaths);
          if (_afterImages.isEmpty) {
            _selectedIndex = 0;
          } else {
            _selectedIndex = _selectedIndex.clamp(0, _afterImages.length - 1);
          }
        }
      }
    });

    if (changed) {
      deleteReportUploadTempFiles(pathsBeforeSync);
    }

    if (!changed) {
      AppHaptics.success();
      AppSnack.show(
        context,
        message: context.l10n.eventsEvidenceNoChanges,
        type: AppSnackType.success,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      builder: (BuildContext ctx) => const CleanupEvidenceSaveResultDialog(
        outcome: CleanupEvidenceSaveOutcome.success,
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _buildImage(String path, {double? height, BoxFit fit = BoxFit.cover}) {
    final String t = path.trim();
    if (t.isEmpty) {
      return Container(
        width: double.infinity,
        height: height,
        color: AppColors.inputFill,
        alignment: Alignment.center,
        child: const Icon(CupertinoIcons.photo, color: AppColors.textMuted),
      );
    }
    if (EcoEventCoverImage.isNetworkUrl(t) || t.startsWith('assets/')) {
      return EcoEventCoverImage(
        path: t,
        width: double.infinity,
        height: height,
        fit: fit,
        errorWidget: const Icon(CupertinoIcons.photo, color: AppColors.textMuted),
      );
    }
    return Image(
      image: FileImage(File(t)),
      width: double.infinity,
      height: height,
      fit: fit,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return Container(
          width: double.infinity,
          height: height,
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: const Icon(CupertinoIcons.photo, color: AppColors.textMuted),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent? event = _event;
    if (event == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: Text(context.l10n.eventsPhotosTitle),
        ),
        body: Center(child: Text(context.l10n.eventsEventNotFoundShort)),
      );
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final bool hasPendingChanges =
        !listEquals(_afterImages, event.afterImagePaths);
    final bool canSave = hasPendingChanges && !_isSaving;

    return PopScope(
      canPop: !hasPendingChanges && !_isSaving,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }
        if (_isSaving) {
          AppSnack.show(
            context,
            message: context.l10n.eventsEvidenceSaveInProgressHint,
            type: AppSnackType.warning,
          );
          return;
        }
        if (hasPendingChanges) {
          _showDiscardDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: AppBackButton(onPressed: () {
            if (_isSaving) {
              AppSnack.show(
                context,
                message: context.l10n.eventsEvidenceSaveInProgressHint,
                type: AppSnackType.warning,
              );
              return;
            }
            if (hasPendingChanges) {
              _showDiscardDialog(context);
            } else {
              Navigator.of(context).maybePop();
            }
          }),
          title: Text(
            context.l10n.eventsEvidenceAppBarTitle,
            style: AppTypography.eventsCalendarMonthTitle(textTheme).copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.l10n.eventsEvidenceScreenSubtitle,
                  style: AppTypography.eventsSupportingCaption(textTheme),
                ),
                const SizedBox(height: AppSpacing.md),
                ValueListenableBuilder<String>(
                  valueListenable: _tab,
                  builder: (BuildContext context, String value, Widget? child) {
                    return Semantics(
                      label: context.l10n.eventsEvidenceBeforeAfterTabsSemantic,
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<String>(
                          groupValue: value,
                          children: <String, Widget>{
                            'before': Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.radiusXl,
                                vertical: AppSpacing.radius10,
                              ),
                              child: Text(context.l10n.eventsBeforeLabel),
                            ),
                            'after': Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.radiusXl,
                                vertical: AppSpacing.radius10,
                              ),
                              child: Text(context.l10n.eventsAfterLabel),
                            ),
                          },
                          onValueChanged: (String? next) {
                            if (next == null) {
                              return;
                            }
                            AppHaptics.tap(context);
                            _tab.value = next;
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + AppSpacing.xxs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Text(
                      context.l10n.eventsEvidencePhotoCountChip(
                        _afterImages.length,
                        _maxAfterImages,
                      ),
                      style: AppTypography.eventsCaptionStrong(
                        textTheme,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _tab,
              builder: (BuildContext context, String value, Widget? child) {
                return AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: value == 'before'
                      ? BeforeTab(
                          key: const ValueKey<String>('before'),
                          event: event,
                          heroHeight: _heroHeight,
                          buildImage: _buildImage,
                        )
                      : AfterTab(
                          key: const ValueKey<String>('after'),
                          afterImages: _afterImages,
                          selectedIndex: _selectedIndex,
                          isPicking: _isPicking,
                          maxImages: _maxAfterImages,
                          heroHeight: _heroHeight,
                          thumbSize: _thumbSize,
                          thumbStripHeight: _thumbStripHeight,
                          onPick: _pickAfterImages,
                          onRemove: _removeAfterImage,
                          onSelect: (int i) =>
                              setState(() => _selectedIndex = i),
                          onImageTap: _openFullscreenGallery,
                          onThumbnailLongPress: _showThumbnailContextMenu,
                          buildImage: _buildImage,
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md + bottomSafe,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: _isSaving
                  ? Semantics(
                      label: context.l10n.eventsEvidenceSavingSemantic,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.42),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const CupertinoActivityIndicator(
                              color: AppColors.textPrimary,
                              radius: 10,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              context.l10n.eventsEvidenceSaving,
                              style: AppTypography.eventsCalendarAgendaTitle(
                                Theme.of(context).textTheme,
                              ).copyWith(
                                letterSpacing: 0.1,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Semantics(
                      button: true,
                      label: context.l10n.commonSave,
                      hint: context.l10n.eventsEvidenceScreenSubtitle,
                      child: PrimaryButton(
                        key: const ValueKey<String>('cleanupEvidenceSave'),
                        label: context.l10n.commonSave,
                        enabled: canSave,
                        onPressed: canSave ? _save : null,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoAlertDialog(
          title: Text(context.l10n.eventsDiscardChangesTitle),
          content: Text(context.l10n.eventsDiscardChangesBody),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.l10n.commonKeepEditing),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.commonDiscard),
            ),
          ],
        );
      },
    );
  }
}
