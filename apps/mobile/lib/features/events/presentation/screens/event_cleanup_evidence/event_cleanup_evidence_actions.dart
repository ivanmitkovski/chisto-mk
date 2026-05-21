part of 'package:chisto_mobile/features/events/presentation/screens/event_cleanup_evidence_screen.dart';

extension EventCleanupEvidenceActions on _EventCleanupEvidenceScreenState {
    Future<void> _pickAfterImages() async {
      final int remaining =
          _EventCleanupEvidenceScreenState._maxAfterImages - _afterImages.length;
      if (remaining <= 0) {
        AppSnack.show(
          context,
          message: context.l10n.eventsEvidenceMaxPhotosSnack(
            _EventCleanupEvidenceScreenState._maxAfterImages,
          ),
          type: AppSnackType.warning,
        );
        return;
      }

      rebuildState(() => _isPicking = true);

      try {
        if (widget.testPickAfterImagePathsOverride != null) {
          final List<String> picked =
              await widget.testPickAfterImagePathsOverride!();
          if (!mounted) {
            return;
          }
          if (picked.isEmpty) {
            rebuildState(() => _isPicking = false);
            return;
          }
          final List<String> next = List<String>.from(_afterImages);
          for (final String path in picked) {
            if (next.length >= _EventCleanupEvidenceScreenState._maxAfterImages) {
              break;
            }
            if (path.trim().isNotEmpty && !next.contains(path)) {
              next.add(path);
            }
          }
          rebuildState(() {
            _afterImages = next;
            _selectedIndex = _selectedIndex.clamp(0, _afterImages.length - 1);
            _isPicking = false;
          });
          return;
        }

        final List<XFile> picked =
            await _picker.pickMultiImage(imageQuality: 86);
        if (picked.isEmpty || !mounted) {
          if (mounted) rebuildState(() => _isPicking = false);
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
          if (next.length >= _EventCleanupEvidenceScreenState._maxAfterImages) {
            break;
          }
          if (saved.trim().isNotEmpty && !next.contains(saved)) {
            next.add(saved);
          }
        }
        if (!mounted) return;
        rebuildState(() {
          _afterImages = next;
          _selectedIndex = _selectedIndex.clamp(0, _afterImages.length - 1);
          _isPicking = false;
        });
      } on Object catch (_) {
        if (!mounted) return;
        logEventsDiagnostic('cleanup_evidence_pick_failed');
        rebuildState(() => _isPicking = false);
        AppSnack.show(
          context,
          message: context.l10n.eventsEvidencePickFailedSnack,
          type: AppSnackType.error,
        );
      }
    }

    void _openFullscreenGallery(int initialIndex) {
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
      rebuildState(() {
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
      rebuildState(() {
        final String path = _afterImages.removeAt(index);
        _afterImages.insert(0, path);
        _selectedIndex = 0;
      });
    }

    void _showThumbnailContextMenu(int index) {
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

      rebuildState(() => _isSaving = true);
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
        rebuildState(() => _isSaving = false);
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
        rebuildState(() => _isSaving = false);
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
      rebuildState(() {
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

}
