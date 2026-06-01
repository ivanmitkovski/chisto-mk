part of 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_screen.dart';

/// End/cancel/extend event flows and organizer toolbar actions during check-in.
class OrganizerCheckInEventLifecycleCoordinator {
  OrganizerCheckInEventLifecycleCoordinator({
    required this.eventsRepository,
    required this.checkInRepository,
    required this.isMounted,
    required this.readContext,
    required this.readEvent,
    required this.readAttendeeCount,
    required this.qrSession,
    required this.attendeeCoordinator,
  });

  final EventsRepository eventsRepository;
  final CheckInRepository checkInRepository;
  final bool Function() isMounted;
  final BuildContext Function() readContext;
  final EcoEvent Function() readEvent;
  final int Function() readAttendeeCount;
  final OrganizerCheckInQrSessionController qrSession;
  final OrganizerCheckInAttendeeCoordinator attendeeCoordinator;

  bool shouldShowEndSoonBanner(EcoEvent event) {
    if (event.status != EcoEventStatus.inProgress) {
      return false;
    }
    final DateTime threshold = event.endDateTime.subtract(
      const Duration(minutes: 10),
    );
    return !DateTime.now().isBefore(threshold);
  }

  void openExtendEnd(EcoEvent event) {
    unawaited(
      showExtendEventEndSheet(
        context: readContext(),
        event: event,
        eventsRepository: eventsRepository,
      ),
    );
  }

  Future<void> showMoreActions() async {
    final BuildContext context = readContext();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext sheetCtx) {
        final AppLocalizations sheetL10n = sheetCtx.l10n;
        return AppSheetScaffold(
          fitToContent: true,
          title: sheetL10n.eventsOrganizerMoreSheetTitle,
          trailing: AppCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: sheetL10n.commonClose,
            onTap: () {
              Navigator.of(sheetCtx).pop();
            },
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppActionTile(
                icon: CupertinoIcons.checkmark_seal_fill,
                title: sheetL10n.eventsOrganizerEndEvent,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  unawaited(onEndEventChosenFromMenu());
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
                title: sheetL10n.eventsOrganizerInvalidateQrTitle,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  unawaited(onInvalidateQrSessionChosen());
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                icon: CupertinoIcons.doc_on_clipboard,
                title: sheetL10n.eventsOrganizerCopyQrText,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  unawaited(copyQrToClipboard());
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppActionTile(
                icon: CupertinoIcons.xmark_circle_fill,
                title: sheetL10n.eventsOrganizerCancelEvent,
                tone: AppSurfaceTone.danger,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  unawaited(onCancelEventChosenFromMenu());
                },
              ),
              if (kDebugMode &&
                  checkInRepository.supportsOrganizerSimulate) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppActionTile(
                  icon: Icons.developer_mode_rounded,
                  title: sheetL10n.eventsOrganizerSimulateCheckInDev,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    unawaited(attendeeCoordinator.simulateCheckIn());
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> onEndEventChosenFromMenu() async {
    await Future<void>.delayed(Duration.zero);
    if (!isMounted()) {
      return;
    }
    final bool ok = await confirmEndEvent();
    if (!isMounted() || !ok) {
      return;
    }
    await completeEndEventAfterConfirm();
  }

  Future<void> onCancelEventChosenFromMenu() async {
    await Future<void>.delayed(Duration.zero);
    if (!isMounted()) {
      return;
    }
    final bool ok = await confirmCancelEvent();
    if (!isMounted() || !ok) {
      return;
    }
    AppHaptics.warning();
    await completeCancelEventAfterConfirm();
  }

  Future<bool> confirmEndEvent() async {
    final BuildContext context = readContext();
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext sheetCtx) {
        final AppLocalizations l10n = sheetCtx.l10n;
        return AppSheetScaffold(
          fitToContent: true,
          title: l10n.eventsOrganizerEndEventConfirmTitle,
          subtitle: l10n.eventsOrganizerEndEventConfirmMessage,
          trailing: AppCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: l10n.commonClose,
            onTap: () {
              Navigator.of(sheetCtx).pop(false);
            },
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton.outlined(
                label: l10n.eventsOrganizerEndEventKeepManaging,
                onPressed: () {
                  Navigator.of(sheetCtx).pop(false);
                },
                expand: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: l10n.eventsOrganizerEndEventConfirmAction,
                enabled: true,
                onPressed: () {
                  Navigator.of(sheetCtx).pop(true);
                },
              ),
            ],
          ),
          child: const SizedBox.shrink(),
        );
      },
    );
    return result ?? false;
  }

  Future<bool> confirmCancelEvent() async {
    final BuildContext context = readContext();
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext sheetCtx) {
        final AppLocalizations l10n = sheetCtx.l10n;
        return AppSheetScaffold(
          fitToContent: true,
          title: l10n.eventsOrganizerCancelEventConfirmTitle,
          subtitle: l10n.eventsOrganizerCancelEventConfirmMessage,
          trailing: AppCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: l10n.commonClose,
            onTap: () {
              Navigator.of(sheetCtx).pop(false);
            },
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton.outlined(
                label: l10n.eventsOrganizerCancelEventKeepEvent,
                onPressed: () {
                  Navigator.of(sheetCtx).pop(false);
                },
                expand: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.destructive(
                label: l10n.eventsOrganizerCancelEventConfirmAction,
                onPressed: () {
                  AppHaptics.warning();
                  Navigator.of(sheetCtx).pop(true);
                },
                expand: true,
              ),
            ],
          ),
          child: const SizedBox.shrink(),
        );
      },
    );
    return result ?? false;
  }

  Future<void> completeEndEventAfterConfirm() async {
    final BuildContext context = readContext();
    final EcoEvent event = readEvent();
    await checkInRepository.closeSession(event.id);
    final bool changed = await eventsRepository.updateStatus(
      event.id,
      EcoEventStatus.completed,
    );
    if (!context.mounted) {
      return;
    }
    if (!changed) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerUnableCompleteEvent,
        type: AppSnackType.warning,
      );
      return;
    }
    AppHaptics.success();
    final OrganizerEventCompletionAction action =
        await showOrganizerEventCompletionSheet(
          context: context,
          checkedInCount: readAttendeeCount(),
          participantCount: event.participantCount,
          maxParticipants: event.maxParticipants,
        );
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    if (!context.mounted) {
      return;
    }
    if (action == OrganizerEventCompletionAction.openEvidence) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted()) {
          return;
        }
        EventsNavigation.openCleanupEvidence(context, eventId: event.id);
      });
    } else if (action == OrganizerEventCompletionAction.openImpactReceipt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted()) {
          return;
        }
        EventsNavigation.openImpactReceipt(context, eventId: event.id);
      });
    }
  }

  Future<void> handlePauseResume() async {
    final BuildContext context = readContext();
    final EcoEvent event = readEvent();
    final bool isOpen = event.isCheckInOpen;
    try {
      final bool changed = isOpen
          ? await checkInRepository.pauseSession(event.id)
          : await checkInRepository.resumeSession(event.id);
      if (!changed) {
        AppHaptics.warning();
        return;
      }
      if (!isOpen) {
        await qrSession.issueNewPayload();
      }
      if (!context.mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: isOpen
            ? context.l10n.eventsOrganizerCheckInPausedSnack
            : context.l10n.eventsOrganizerCheckInResumedSnack,
        type: AppSnackType.success,
      );
    } on AppError catch (e) {
      AppHaptics.warning();
      if (!context.mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: localizedAppErrorMessage(context.l10n, e),
        type: AppSnackType.warning,
      );
    } on Object catch (_) {
      AppHaptics.warning();
      if (!context.mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerCheckInPauseResumeFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> completeCancelEventAfterConfirm() async {
    final BuildContext context = readContext();
    final EcoEvent event = readEvent();
    await checkInRepository.closeSession(event.id);
    final bool changed = await eventsRepository.updateStatus(
      event.id,
      EcoEventStatus.cancelled,
    );
    if (!context.mounted) {
      return;
    }
    if (!changed) {
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerUnableCancelEvent,
        type: AppSnackType.warning,
      );
      return;
    }
    AppSnack.show(
      context,
      message: context.l10n.eventsOrganizerEventCancelledSnack,
      type: AppSnackType.warning,
    );
    Navigator.of(context).pop();
  }

  Future<void> onInvalidateQrSessionChosen() async {
    await Future<void>.delayed(Duration.zero);
    if (!isMounted()) {
      return;
    }
    final BuildContext context = readContext();
    if (!context.mounted) {
      return;
    }
    final EcoEvent event = readEvent();
    final bool? ok = await showOrganizerInvalidateQrSessionSheet(context);
    if (!context.mounted || ok != true) {
      return;
    }
    try {
      await checkInRepository.rotateSession(event.id);
      if (!isMounted()) {
        return;
      }
      await qrSession.issueNewPayload();
      if (!context.mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerQrSessionRotated,
        type: AppSnackType.success,
      );
    } on AppError catch (_) {
      if (!context.mounted) {
        return;
      }
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerQrRotateFailed,
        type: AppSnackType.warning,
      );
    } on Object {
      if (!context.mounted) {
        return;
      }
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerQrRotateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> copyQrToClipboard() async {
    final BuildContext context = readContext();
    final CheckInQrPayload? payload = qrSession.payload;
    if (payload == null) {
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerNoQrToCopy,
        type: AppSnackType.warning,
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: payload.encode()));
    if (!context.mounted) {
      return;
    }
    AppSnack.show(
      context,
      message: context.l10n.eventsOrganizerQrTextCopied,
      type: AppSnackType.success,
    );
  }
}
