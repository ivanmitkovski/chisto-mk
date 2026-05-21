part of 'package:chisto_mobile/features/events/presentation/screens/event_detail_screen.dart';

extension EventDetailAttendeeActions on _EventDetailScreenState {
    Future<void> _handleToggleJoin(EcoEvent event) async {
      if (!event.isJoined && !event.canVolunteerJoinNow) {
        AppHaptics.warning();
        AppSnack.show(
          context,
          message: context.l10n.eventsJoinWindowClosed,
          type: AppSnackType.warning,
        );
        return;
      }
      if (!event.isJoined &&
          event.maxParticipants != null &&
          event.participantCount >= event.maxParticipants!) {
        AppHaptics.warning();
        AppSnack.show(
          context,
          message: context.l10n.eventsEventFull,
          type: AppSnackType.warning,
        );
        return;
      }
      await _withCtaMutationBusy(() async {
        EcoEventJoinToggleResult joinResult = const EcoEventJoinToggleResult(
          changed: false,
        );
        try {
          joinResult = await _eventsStore.toggleJoin(event.id);
          if (!joinResult.changed) {
            AppHaptics.warning();
            if (mounted) {
              AppSnack.show(
                context,
                message: context.l10n.eventsParticipationUpdateFailed,
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
        final EcoEvent? updated = _eventsStore.findById(event.id);
        if (updated != null) {
          unawaited(_refreshChatUnread(updated));
        }
        final bool joined = updated?.isJoined ?? false;
        final String message = !joined
            ? context.l10n.eventsLeftEcoAction
            : joinResult.pointsAwarded > 0
            ? context.l10n.eventsJoinPointsEarned(joinResult.pointsAwarded)
            : context.l10n.eventsJoinedEcoAction;
        AppSnack.show(context, message: message, type: AppSnackType.success);
      });
    }

    Future<void> _handleToggleReminder(EcoEvent event) async {
      AppHaptics.tap();
      if (!event.isJoined) {
        AppSnack.show(
          context,
          message: context.l10n.eventsJoinFirstForReminders,
          type: AppSnackType.warning,
        );
        return;
      }
      if (event.reminderEnabled) {
        await _withCtaMutationBusy(() async {
          try {
            final bool changed = await _eventsStore.setReminder(
              eventId: event.id,
              enabled: false,
              reminderAt: null,
            );
            if (changed) {
              if (mounted) {
                AppSnack.show(
                  context,
                  message: context.l10n.eventsReminderDisabled,
                  type: AppSnackType.success,
                );
              }
            }
          } on AppError catch (e) {
            if (mounted) {
              AppSnack.show(
                context,
                message: localizedAppErrorMessage(context.l10n, e),
                type: AppSnackType.warning,
              );
            }
          }
        });
        return;
      }

      await _handleEnableReminder(event);
    }

    Future<void> _handleEnableReminder(EcoEvent event) async {
      final DateTime? selectedReminder = await ReminderPickerSheet.show(
        context,
        event,
      );
      if (!mounted || selectedReminder == null) {
        return;
      }
      await _withCtaMutationBusy(() async {
        try {
          final bool changed = await _eventsStore.setReminder(
            eventId: event.id,
            enabled: true,
            reminderAt: selectedReminder,
          );
          if (!changed) {
            return;
          }
        } on AppError catch (e) {
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
        AppSnack.show(
          context,
          message: context.l10n.eventsReminderSetSnack(
            ReminderPickerSheet.formatReminderLabel(selectedReminder),
          ),
          type: AppSnackType.success,
        );
      });
    }

    void _openEditEvent(EcoEvent event) {
      showEventsSurfaceModal<void>(
        context: context,
        builder: (BuildContext sheetCtx) => EditEventSheet(event: event),
      );
    }

    void _openExtendCleanupEnd(EcoEvent event) {
      AppHaptics.tap();
      unawaited(
        showExtendEventEndSheet(
          context: context,
          event: event,
          eventsRepository: _eventsStore,
        ),
      );
    }

    bool _shouldShowOrganizerEndSoonBanner(EcoEvent event) {
      if (!event.isOrganizer || event.status != EcoEventStatus.inProgress) {
        return false;
      }
      final DateTime threshold = event.endDateTime.subtract(
        const Duration(minutes: 10),
      );
      return !DateTime.now().isBefore(threshold);
    }

    Future<void> _handleAddToCalendar(EcoEvent event) async {
      try {
        await EventCalendarExport.addToCalendar(event);
        if (!mounted) {
          return;
        }
        AppHaptics.light();
        AppSnack.show(
          context,
          message: context.l10n.eventsDetailCalendarAdded,
          type: AppSnackType.success,
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        AppHaptics.warning();
        AppSnack.show(
          context,
          message: context.l10n.eventsDetailCalendarFailed,
          type: AppSnackType.warning,
        );
      }
    }

    Future<void> _handleOpenAttendeeCheckIn(EcoEvent event) async {
      if (event.isCheckedIn) {
        AppSnack.show(
          context,
          message: context.l10n.eventsAttendeeAlreadyCheckedInSnack,
          type: AppSnackType.success,
        );
        return;
      }
      if (!event.canOpenAttendeeCheckIn) {
        AppSnack.show(
          context,
          message: context.l10n.eventsAttendeeCheckInPausedSnack,
          type: AppSnackType.warning,
        );
        return;
      }
      final bool? success = await EventsNavigation.openAttendeeQrScanner(
        context,
        eventId: event.id,
      );
      if (!mounted || success != true) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsAttendeeCheckInCompleteSnack,
        type: AppSnackType.success,
      );
    }

}
