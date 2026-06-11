part of 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_screen.dart';

/// Attendee list polling, manual add/remove, and scan feedback for organizer check-in.
class OrganizerCheckInAttendeeCoordinator {
  OrganizerCheckInAttendeeCoordinator({
    required this.eventId,
    required this.checkInRepository,
    required this.isMounted,
    required this.readContext,
    required this.readEvent,
    required this.onStateChanged,
    required this.qrSession,
    required this.mapCheckInAppError,
  });

  final String eventId;
  final CheckInRepository checkInRepository;
  final bool Function() isMounted;
  final BuildContext Function() readContext;
  final EcoEvent Function() readEvent;
  final VoidCallback onStateChanged;
  final OrganizerCheckInQrSessionController qrSession;
  final String Function(AppError error) mapCheckInAppError;

  static const int _pollIntervalSeconds = 12;

  final Random _rnd = Random();
  Timer? _pollTimer;
  final Set<String> _dismissedAttendeeIds = <String>{};

  List<CheckedInAttendee> visibleAttendees() {
    return checkInRepository
        .checkedInAttendees(eventId)
        .where((CheckedInAttendee a) => !_dismissedAttendeeIds.contains(a.id))
        .toList(growable: false);
  }

  void startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: _pollIntervalSeconds), (
      _,
    ) {
      if (!isMounted()) {
        return;
      }
      final EcoEvent event = readEvent();
      if (event.isCheckInOpen) {
        unawaited(checkInRepository.refreshAttendees(event.id));
      }
    });
  }

  void onAppResumed() {
    if (!isMounted()) {
      return;
    }
    unawaited(checkInRepository.refreshAttendees(readEvent().id));
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> addManualAttendee() async {
    final BuildContext context = readContext();
    final EcoEvent event = readEvent();
    final EventParticipantRow? picked =
        await AppBottomSheet.show<EventParticipantRow?>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: AppColors.transparent,
          builder: (BuildContext sheetCtx) {
            final MediaQueryData mq = MediaQuery.of(sheetCtx);
            return MediaQuery(
              data: mq.copyWith(viewInsets: EdgeInsets.zero),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: mq.size.width,
                  child: ManualCheckInSheet(eventId: event.id),
                ),
              ),
            );
          },
        );
    if (!isMounted()) {
      return;
    }
    if (picked == null) {
      return;
    }
    try {
      final ManualCheckInResult added = await checkInRepository
          .markAttendeeCheckedIn(
            eventId: event.id,
            attendeeId: picked.userId,
            attendeeName: picked.displayName,
          );
      if (!context.mounted) {
        return;
      }
      if (!added.recorded) {
        AppSnack.show(
          context,
          message: context.l10n.eventsOrganizerNameAlreadyCheckedIn(
            picked.displayName,
          ),
          type: AppSnackType.warning,
        );
        return;
      }
      final String successMessage = added.pointsAwarded > 0
          ? context.l10n.eventsManualCheckInWithPoints(
              picked.displayName,
              added.pointsAwarded,
            )
          : context.l10n.eventsOrganizerNameAddedByOrganizer(
              picked.displayName,
            );
      AppSnack.show(
        context,
        message: successMessage,
        type: AppSnackType.success,
      );
      await qrSession.issueNewPayload();
    } on AppError catch (e) {
      if (!context.mounted) {
        return;
      }
      if (e.code == 'CHECK_IN_REQUIRES_JOIN') {
        AppSnack.show(
          context,
          message: context.l10n.eventsOrganizerManualCheckInNotParticipant,
          type: AppSnackType.warning,
        );
        return;
      }
      final String mapped = mapCheckInAppError(e);
      AppSnack.show(
        context,
        message: mapped.trim().isNotEmpty
            ? mapped
            : context.l10n.eventsOrganizerUnableCompleteEvent,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> removeAttendee(CheckedInAttendee attendee) async {
    _dismissedAttendeeIds.add(attendee.id);
    onStateChanged();

    final EcoEvent event = readEvent();
    final bool removed = await checkInRepository.removeCheckedInAttendee(
      eventId: event.id,
      attendeeId: attendee.id,
    );
    if (!isMounted()) {
      return;
    }
    final BuildContext context = readContext();
    if (!context.mounted) {
      return;
    }
    if (!removed) {
      _dismissedAttendeeIds.remove(attendee.id);
      onStateChanged();
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerCouldNotRemoveName(attendee.name),
        type: AppSnackType.warning,
      );
      return;
    }
    _dismissedAttendeeIds.remove(attendee.id);
    AppSnack.show(
      context,
      message: context.l10n.eventsOrganizerNameRemovedFromCheckIn(
        attendee.name,
      ),
      type: AppSnackType.warning,
    );
  }

  Future<void> simulateCheckIn() async {
    if (qrSession.payload == null) {
      await qrSession.issueNewPayload();
      return;
    }
    const List<String> mockNames = <String>[
      'mock_attendee_1',
      'mock_attendee_2',
      'mock_attendee_3',
      'mock_attendee_4',
      'mock_attendee_5',
      'mock_attendee_6',
      'mock_attendee_7',
    ];
    final List<CheckedInAttendee> attendees = visibleAttendees();
    final List<String> available = mockNames
        .where((String name) {
          final String id = 'att_${name.toLowerCase().replaceAll(' ', '_')}';
          return !attendees.any((CheckedInAttendee a) => a.id == id);
        })
        .toList(growable: false);
    final BuildContext context = readContext();
    if (available.isEmpty) {
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerMockAllCheckedIn,
        type: AppSnackType.warning,
      );
      return;
    }

    final String name = available[_rnd.nextInt(available.length)];
    final String attendeeId = 'att_${name.toLowerCase().replaceAll(' ', '_')}';
    final EcoEvent event = readEvent();
    final CheckInSubmissionResult result = await checkInRepository.submitScan(
      rawPayload: qrSession.payload!.encode(),
      expectedEventId: event.id,
      attendeeId: attendeeId,
      attendeeName: name,
    );
    if (!isMounted()) {
      return;
    }
    showSubmissionFeedback(result, name);
    if (result.isSuccess ||
        result.isPendingConfirmation ||
        result.status == CheckInSubmissionStatus.alreadyCheckedIn) {
      await qrSession.issueNewPayload();
    }
  }

  void showSubmissionFeedback(CheckInSubmissionResult result, String name) {
    final BuildContext context = readContext();
    final AppLocalizations l10n = context.l10n;
    final String message = switch (result.status) {
      CheckInSubmissionStatus.success =>
        result.pointsAwarded > 0
            ? l10n.eventsManualCheckInWithPoints(name, result.pointsAwarded)
            : l10n.eventsOrganizerFeedbackCheckedIn(name),
      CheckInSubmissionStatus.invalidFormat =>
        l10n.eventsOrganizerFeedbackInvalidQr,
      CheckInSubmissionStatus.invalidQr =>
        l10n.eventsOrganizerFeedbackInvalidQrStrict,
      CheckInSubmissionStatus.wrongEvent =>
        l10n.eventsOrganizerFeedbackWrongEvent,
      CheckInSubmissionStatus.sessionClosed =>
        l10n.eventsOrganizerFeedbackPaused,
      CheckInSubmissionStatus.sessionExpired =>
        l10n.eventsOrganizerFeedbackQrExpired,
      CheckInSubmissionStatus.replayDetected =>
        l10n.eventsOrganizerFeedbackQrReplay,
      CheckInSubmissionStatus.alreadyCheckedIn =>
        l10n.eventsOrganizerFeedbackAlreadyCheckedIn(name),
      CheckInSubmissionStatus.requiresJoin =>
        l10n.eventsOrganizerFeedbackRequiresJoin,
      CheckInSubmissionStatus.checkInUnavailable =>
        l10n.eventsOrganizerFeedbackCheckInUnavailable,
      CheckInSubmissionStatus.rateLimited =>
        l10n.eventsOrganizerFeedbackRateLimited,
      CheckInSubmissionStatus.queuedOffline => l10n.eventsOfflineSyncQueued,
      CheckInSubmissionStatus.pendingConfirmation =>
        l10n.eventsVolunteerPendingSubtitle,
    };
    if (result.isSuccess) {
      AppHaptics.success();
    }
    AppSnack.show(
      context,
      message: message,
      type: result.isSuccess ? AppSnackType.success : AppSnackType.warning,
    );
  }
}
