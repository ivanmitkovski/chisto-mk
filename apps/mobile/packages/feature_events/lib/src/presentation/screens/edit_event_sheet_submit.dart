part of 'edit_event_sheet.dart';

// State is split across part-file extensions on _EditEventSheetState; setState
// runs on that State instance, which the analyzer cannot see through here.
// ignore_for_file: invalid_use_of_protected_member
extension _EditEventSheetSubmit on _EditEventSheetState {
  Future<void> _scrollToFirstError() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final String title = _titleController.text.trim();
    if (editEventTitleIssueKey(title) != null) {
      _titleFocus.requestFocus();
      final BuildContext? ctx = _titleFocus.context;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.fast,
          curve: AppMotion.smooth,
        );
      }
      if (!mounted) {
        return;
      }
      return;
    }
    final String description = _descriptionController.text.trim();
    if (editEventDescriptionIssueKey(description) != null) {
      _descriptionFocus.requestFocus();
      final BuildContext? ctx = _descriptionFocus.context;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.fast,
          curve: AppMotion.smooth,
        );
      }
      if (!mounted) {
        return;
      }
      return;
    }
    if (editEventMaxParticipantsIssueKey(
          _maxParticipantsController.text.trim(),
        ) !=
        null) {
      _maxParticipantsFocus.requestFocus();
      final BuildContext? ctx = _maxParticipantsFocus.context;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.fast,
          curve: AppMotion.smooth,
        );
      }
    }
  }

  Future<void> _showDuplicateSubmitDialog(AppError error) async {
    final DuplicateEventConflictUi? dup = duplicateEventConflictUiFromAppError(
      error,
    );
    if (!mounted) {
      return;
    }
    if (dup == null) {
      AppSnack.show(
        context,
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
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(ctx.l10n.editEventDuplicateSubmitTitle),
        content: Text(ctx.l10n.editEventDuplicateSubmitBody(dup.title, when)),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonGotIt),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!_isValid) {
      AppHaptics.warning();
      setState(() => _showValidationErrors = true);
      await _scrollToFirstError();
      return;
    }

    final List<ConnectivityResult> connectivity =
        await ConnectivityGate.check();
    if (!mounted) {
      return;
    }
    final bool online = ConnectivityGate.isOnline(connectivity);
    if (!online) {
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.editEventOfflineSave,
        type: AppSnackType.warning,
      );
      return;
    }

    final bool? goAhead = await _scheduleConflict.confirmProceedDespiteConflict(
      context,
    );
    if (goAhead != true || !mounted) {
      return;
    }

    final DateTime startDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final DateTime endCal = DateUtils.dateOnly(_selectedDate);
    final DateTime endDt = DateTime(
      endCal.year,
      endCal.month,
      endCal.day,
      _endTime.hour,
      _endTime.minute,
    );

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
      AppSnack.show(
        context,
        message: context.l10n.editEventNoChangesToSave,
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await readEventsRepository().updateEventDetails(_event.id, payload);
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      if (e.code == 'DUPLICATE_EVENT') {
        await _showDuplicateSubmitDialog(e);
      } else {
        AppSnack.show(
          context,
          message: localizedAppErrorMessage(context.l10n, e),
          type: AppSnackType.warning,
        );
      }
      return;
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      AppSnack.show(
        context,
        message: context.l10n.eventsMutationFailedGeneric,
        type: AppSnackType.warning,
      );
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    AppSnack.show(
      context,
      message: context.l10n.eventsEventUpdated,
      type: AppSnackType.success,
    );
    Navigator.of(context, rootNavigator: true).pop();
  }

  String? _titleError(AppLocalizations l10n) {
    if (!_showValidationErrors) {
      return null;
    }
    final String key =
        editEventTitleIssueKey(_titleController.text.trim()) ?? '';
    if (key == 'tooShort') {
      return l10n.createEventTitleMinLength;
    }
    if (key == 'tooLong') {
      return l10n.editEventTitleTooLong(kEditEventTitleMaxLength);
    }
    return null;
  }

  String? _descriptionError(AppLocalizations l10n) {
    if (!_showValidationErrors) {
      return null;
    }
    if (editEventDescriptionIssueKey(_descriptionController.text.trim()) ==
        'tooLong') {
      return l10n.editEventDescriptionTooLong(kEditEventDescriptionMaxLength);
    }
    return null;
  }

  String? _maxParticipantsError(AppLocalizations l10n) {
    if (!_showValidationErrors) {
      return null;
    }
    final String key =
        editEventMaxParticipantsIssueKey(
          _maxParticipantsController.text.trim(),
        ) ??
        '';
    if (key == 'invalid') {
      return l10n.editEventMaxParticipantsInvalid;
    }
    if (key == 'range') {
      return l10n.editEventMaxParticipantsRange(
        kEditEventMaxParticipantsMin,
        kEditEventMaxParticipantsMax,
      );
    }
    return null;
  }
}
