part of 'edit_event_sheet.dart';

// State is split across part-file extensions on _EditEventSheetState; setState
// runs on that State instance, which the analyzer cannot see through here.
// ignore_for_file: invalid_use_of_protected_member
extension _EditEventSheetSubmit on _EditEventSheetState {
  Future<void> _showDuplicateSubmitDialog(
    AppError error, {
    required BuildContext dialogContext,
  }) async {
    final DuplicateEventConflictUi? dup = duplicateEventConflictUiFromAppError(
      error,
    );
    if (!mounted) {
      return;
    }
    final BuildContext host = _snackHostContext();
    if (dup == null) {
      AppSnack.show(
        host,
        message: localizedAppErrorMessage(context.l10n, error),
        type: AppSnackType.warning,
      );
      return;
    }
    final String when = _scheduleConflict.formatConflictWhen(
      context,
      dup.scheduledAt,
    );
    if (!mounted) {
      return;
    }
    await AppConfirmDialog.showInfo(
      context: dialogContext,
      title: dialogContext.l10n.editEventDuplicateSubmitTitle,
      body: dialogContext.l10n.editEventDuplicateSubmitBody(dup.title, when),
      confirmLabel: dialogContext.l10n.commonGotIt,
    );
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _submitFeedbackMessage = null;
    });

    try {
      final AppLocalizations l10n = context.l10n;
      final BuildContext snackHost = _snackHostContext();
      final BuildContext dialogHost = snackHost;

      if (await handleInvalidSubmit(
        context,
        l10n,
        _editEventFieldOrder,
        _validators(l10n),
      )) {
        if (!mounted) {
          return;
        }
        final String? firstError = _firstSubmitValidationError(l10n);
        final int invalidCount = countInvalidFields(
          _editEventFieldOrder,
          _validators(l10n),
        );
        setState(() {
          _submitFeedbackMessage =
              firstError ??
              l10n.formValidationErrorsAnnounce(invalidCount);
        });
        return;
      }

      final List<ConnectivityResult> connectivity =
          await ConnectivityGate.check();
      if (!mounted) {
        return;
      }
      final bool online = ConnectivityGate.isOnline(connectivity);
      if (!online) {
        setState(() {
          _submitFeedbackMessage = l10n.editEventOfflineSave;
        });
        AppSnack.show(
          snackHost,
          message: l10n.editEventOfflineSave,
          type: AppSnackType.warning,
        );
        return;
      }

      final bool? goAhead = await _scheduleConflict
          .confirmProceedDespiteConflict(dialogHost);
      if (goAhead != true || !mounted) {
        return;
      }

      final DateTime startDay = DateUtils.dateOnly(_selectedDate);
      final DateTime startDt = eventScheduleInstantLocal(
        startDay,
        _startTime,
      );
      final DateTime endDt = eventScheduleInstantLocal(startDay, _endTime);

      final String titleTrimmed = _titleController.text.trim();
      final String descriptionTrimmed = _descriptionController.text.trim();
      final int? maxParticipants = editEventParsedMaxParticipants(
        _maxParticipantsController.text.trim(),
      );
      final List<EventGear> gearList = _gear.toList(growable: false)
        ..sort((EventGear a, EventGear b) => a.name.compareTo(b.name));

      final EventUpdatePayload payload = _initialSnapshot.buildPartialPayload(
        titleTrimmed: titleTrimmed,
        descriptionTrimmed: descriptionTrimmed,
        maxParticipants: maxParticipants,
        scheduledAtUtc: startDt.toUtc(),
        endAtUtc: endDt.toUtc(),
        category: _category,
        gear: gearList,
        scale: _scale,
        difficulty: _difficulty,
      );

      if (payload.toPatchJson().isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _submitFeedbackMessage = l10n.editEventNoChangesToSave;
        });
        AppSnack.show(
          snackHost,
          message: l10n.editEventNoChangesToSave,
          type: AppSnackType.warning,
        );
        return;
      }

      await readEventsRepository().updateEventDetails(_event.id, payload);

      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      AppSnack.show(
        snackHost,
        message: l10n.eventsEventUpdated,
        type: AppSnackType.success,
      );
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == 'DUPLICATE_EVENT') {
        await _showDuplicateSubmitDialog(
          e,
          dialogContext: _snackHostContext(),
        );
      } else {
        final String message = localizedAppErrorMessage(context.l10n, e);
        setState(() => _submitFeedbackMessage = message);
        AppSnack.show(
          _snackHostContext(),
          message: message,
          type: AppSnackType.warning,
        );
      }
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitFeedbackMessage = context.l10n.eventsMutationFailedGeneric;
      });
      AppSnack.show(
        _snackHostContext(),
        message: context.l10n.eventsMutationFailedGeneric,
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _titleError(AppLocalizations l10n) {
    return validateIfVisible(
      _EditEventFieldIds.title,
      _validators(l10n)[_EditEventFieldIds.title]!,
    );
  }

  String? _descriptionError(AppLocalizations l10n) {
    return validateIfVisible(
      _EditEventFieldIds.description,
      _validators(l10n)[_EditEventFieldIds.description]!,
    );
  }

  String? _maxParticipantsError(AppLocalizations l10n) {
    return validateIfVisible(
      _EditEventFieldIds.maxParticipants,
      _validators(l10n)[_EditEventFieldIds.maxParticipants]!,
    );
  }
}
