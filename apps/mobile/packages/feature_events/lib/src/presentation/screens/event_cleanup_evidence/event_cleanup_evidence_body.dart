part of 'package:feature_events/src/presentation/screens/event_cleanup_evidence_screen.dart';

extension EventCleanupEvidenceBody on _EventCleanupEvidenceScreenState {
  Widget buildEventCleanupEvidenceBody(BuildContext context) {
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
    final bool hasPendingChanges = !listEquals(
      _afterImages,
      event.afterImagePaths,
    );
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
          leading: AppBackButton(
            onPressed: () {
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
            },
          ),
          title: Text(
            context.l10n.eventsEvidenceAppBarTitle,
            style: AppTypography.eventsCalendarMonthTitle(
              textTheme,
            ).copyWith(color: AppColors.textPrimary),
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
                    builder:
                        (BuildContext context, String value, Widget? child) {
                          return Semantics(
                            label: context
                                .l10n
                                .eventsEvidenceBeforeAfterTabsSemantic,
                            child: SizedBox(
                              width: double.infinity,
                              child: CupertinoSlidingSegmentedControl<String>(
                                groupValue: value,
                                children: <String, Widget>{
                                  'before': Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.radiusXl,
                                      vertical: AppSpacing.radius10,
                                    ),
                                    child: Text(context.l10n.eventsBeforeLabel),
                                  ),
                                  'after': Padding(
                                    padding: const EdgeInsets.symmetric(
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Text(
                        context.l10n.eventsEvidencePhotoCountChip(
                          _afterImages.length,
                          _EventCleanupEvidenceScreenState._maxAfterImages,
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
            if (event.evidenceStrip.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: EventEvidenceStripSection(
                  items: event.evidenceStrip,
                  compactSubtitle: true,
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
                            heroHeight:
                                _EventCleanupEvidenceScreenState._heroHeight,
                            buildImage: _buildImage,
                          )
                        : AfterTab(
                            key: const ValueKey<String>('after'),
                            afterImages: _afterImages,
                            selectedIndex: _selectedIndex,
                            isPicking: _isPicking,
                            maxImages: _EventCleanupEvidenceScreenState
                                ._maxAfterImages,
                            heroHeight:
                                _EventCleanupEvidenceScreenState._heroHeight,
                            thumbSize:
                                _EventCleanupEvidenceScreenState._thumbSize,
                            thumbStripHeight: _EventCleanupEvidenceScreenState
                                ._thumbStripHeight,
                            onPick: _pickAfterImages,
                            onRemove: _removeAfterImage,
                            onSelect: (int i) =>
                                rebuildState(() => _selectedIndex = i),
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
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
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
                                style:
                                    AppTypography.eventsCalendarAgendaTitle(
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
    unawaited(() async {
      final bool? discard = await AppConfirmDialog.show(
        context: context,
        title: context.l10n.eventsDiscardChangesTitle,
        body: context.l10n.eventsDiscardChangesBody,
        confirmLabel: context.l10n.commonDiscard,
        cancelLabel: context.l10n.commonKeepEditing,
        isDestructive: true,
      );
      if ((discard ?? false) && context.mounted) {
        Navigator.of(context).pop();
      }
    }());
  }
}
