part of 'package:feature_events/src/presentation/screens/event_detail_screen.dart';

extension EventDetailOrganizerActions on _EventDetailScreenState {
  Future<void> _editFeedback(EcoEvent event) async {
    final EventFeedbackSnapshot? current = _feedbackSnapshot;
    final EventFeedbackSnapshot? updated = await _showFeedbackSheet(
      event,
      current,
    );
    if (!mounted || updated == null) {
      return;
    }
    await _feedbackCache.write(updated);
    if (!mounted) {
      return;
    }
    rebuildState(() {
      _feedbackSnapshot = updated;
    });
    AppSnack.show(
      context,
      message: current == null
          ? context.l10n.eventsImpactSummarySaved
          : context.l10n.eventsImpactSummaryUpdated,
      type: AppSnackType.success,
    );
  }

  Future<void> _saveBagsCollected(EcoEvent event, int bagsCollected) async {
    final int clamped = bagsCollected.clamp(0, 9999);
    final EventFeedbackSnapshot? cur = _feedbackSnapshot;
    final EventFeedbackSnapshot next = EventFeedbackSnapshot(
      eventId: event.id,
      rating: cur?.rating ?? 5,
      bagsCollected: clamped,
      volunteerHours: cur?.volunteerHours ?? 2.0,
      notes: cur?.notes ?? '',
      createdAt: cur?.createdAt ?? DateTime.now(),
    );
    await _feedbackCache.write(next);
    if (!mounted) {
      return;
    }
    rebuildState(() {
      _feedbackSnapshot = next;
    });
    AppHaptics.success();
    AppSnack.show(
      context,
      message: context.l10n.eventsCompletedBagsSaved,
      type: AppSnackType.success,
    );
    unawaited(_pushLiveImpactBags(event.id, clamped));
  }

  Future<void> _pushLiveImpactBags(String eventId, int bags) async {
    try {
      final bool ok = await readEventsRepository().pushLiveImpactBags(
        eventId,
        bags,
      );
      if (!ok) {
        await FieldModeQueue.instance.enqueueLiveImpactBags(
          eventId: eventId,
          reportedBagsCollected: bags,
        );
        return;
      }
      await readEventsRepository().prefetchEvent(eventId, force: true);
    } on Object {
      await FieldModeQueue.instance.enqueueLiveImpactBags(
        eventId: eventId,
        reportedBagsCollected: bags,
      );
    }
  }

  Future<EventFeedbackSnapshot?> _showFeedbackSheet(
    EcoEvent event,
    EventFeedbackSnapshot? current,
  ) async {
    return AppBottomSheet.show<EventFeedbackSnapshot>(
      context: context,
      keyboardInsetMode: SheetKeyboardInsetMode.overlay,
      builder: (BuildContext sheetCtx) =>
          buildEventFeedbackSheet(sheetCtx, event: event, current: current),
    );
  }

  Future<void> _handleStartEvent(EcoEvent event) async {
    if (event.isBeforeScheduledStart) {
      AppHaptics.warning();
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsStartEventTooEarly,
          type: AppSnackType.warning,
        );
      }
      return;
    }
    await _withCtaMutationBusy(() async {
      try {
        final bool changed = await _eventsStore.updateStatus(
          event.id,
          EcoEventStatus.inProgress,
        );
        if (!changed) {
          AppHaptics.warning();
          if (mounted) {
            AppSnack.show(
              context,
              message: context.l10n.eventsUnableToStartEventGeneric,
              type: AppSnackType.warning,
            );
          }
          return;
        }
      } on AppError catch (e) {
        AppHaptics.warning();
        if (mounted) {
          AppSnack.show(
            context,
            message: localizedAppErrorMessage(context.l10n, e),
            type: AppSnackType.warning,
          );
        }
        return;
      }
      if (!mounted) {
        return;
      }
      final EcoEvent startedEvent =
          _eventsStore.findById(event.id) ??
          event.copyWith(status: EcoEventStatus.inProgress);
      unawaited(
        EventsNavigation.openOrganizerCheckIn(
          context,
          eventId: startedEvent.id,
        ),
      );
    });
  }

  void _handleManageCheckIn(EcoEvent event) {
    if (event.status != EcoEventStatus.inProgress) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsManageCheckInOnlyInProgress,
        type: AppSnackType.warning,
      );
      return;
    }
    EventsNavigation.openOrganizerCheckIn(context, eventId: event.id);
  }

  void _handleOpenCleanupEvidence(EcoEvent event) {
    if (!event.isOrganizer || event.status != EcoEventStatus.completed) {
      AppHaptics.warning();
      return;
    }
    EventsNavigation.openCleanupEvidence(context, eventId: event.id);
  }
}
