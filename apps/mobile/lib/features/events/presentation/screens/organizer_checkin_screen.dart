// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/events/data/check_in_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/socket_check_in_stream.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/utils/organizer_end_soon_local_controller.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/extend_event_end_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/organizer_checkin/organizer_checkin_widgets.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';

/// Organizer check-in screen: displays a QR code attendees scan.
/// After each scan the QR regenerates. Checked-in names appear in the list.
class OrganizerCheckInScreen extends StatefulWidget {
  const OrganizerCheckInScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<OrganizerCheckInScreen> createState() => _OrganizerCheckInScreenState();
}

class _OrganizerCheckInScreenState extends State<OrganizerCheckInScreen>
    with WidgetsBindingObserver {
  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
  final CheckInRepository _checkInRepository =
      CheckInRepositoryRegistry.instance;
  final OrganizerEndSoonLocalController _organizerEndSoonLocal =
      OrganizerEndSoonLocalController();
  final Random _rnd = Random();
  CheckInQrPayload? _payload;
  Timer? _refreshTicker;
  Timer? _attendeePollTimer;

  /// Decouples QR countdown UI from full-screen [setState] on every tick.
  final ValueNotifier<int> _countdownSeconds = ValueNotifier<int>(0);
  String? _qrLoadError;
  bool _isIssuingPayload = false;
  // IDs optimistically hidden while an async removal is in-flight.
  // Prevents Dismissible from asserting the widget is still in the tree.
  final Set<String> _dismissedAttendeeIds = {};

  static const int _attendeeListPollIntervalSeconds = 12;

  // --- Organizer confirmation via WebSocket ---
  SocketCheckInStream? _checkInWs;
  StreamSubscription<CheckInStreamEvent>? _checkInWsSub;
  final List<CheckInRequestEvent> _pendingConfirmQueue =
      <CheckInRequestEvent>[];
  bool _isShowingConfirmSheet = false;
  bool _isResolvingPending = false;

  EcoEvent? get _eventOrNull => _eventsRepository.findById(widget.eventId);

  EcoEvent get _event => _eventOrNull!;

  List<CheckedInAttendee> get _attendees => _checkInRepository
      .checkedInAttendees(_event.id)
      .where((CheckedInAttendee a) => !_dismissedAttendeeIds.contains(a.id))
      .toList(growable: false);

  int get _deadlineMs {
    final CheckInQrPayload? payload = _payload;
    if (payload == null) {
      return 0;
    }
    return payload.expiresAtMs ??
        payload.issuedAtMs + _checkInRepository.payloadTtl.inMilliseconds;
  }

  int get _remainingPayloadMs {
    if (_payload == null) {
      return 0;
    }
    final int left = _deadlineMs - DateTime.now().millisecondsSinceEpoch;
    return left.clamp(0, 86400000);
  }

  int get _remainingPayloadSeconds => (_remainingPayloadMs / 1000).ceil();

  void _syncCountdownNotifier() {
    if (_payload == null) {
      if (_countdownSeconds.value != 0) {
        _countdownSeconds.value = 0;
      }
      return;
    }
    final int next = _remainingPayloadSeconds;
    if (next != _countdownSeconds.value) {
      _countdownSeconds.value = next;
    }
  }

  void _startAttendeePollTimer() {
    _attendeePollTimer?.cancel();
    _attendeePollTimer = Timer.periodic(
      const Duration(seconds: _attendeeListPollIntervalSeconds),
      (_) {
        if (!context.mounted) {
          return;
        }
        final EcoEvent? ev = _eventOrNull;
        if (ev != null && ev.isCheckInOpen) {
          unawaited(_checkInRepository.refreshAttendees(ev.id));
        }
      },
    );
  }

  double _qrDisplaySize(BuildContext context) {
    final double shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest * 0.62).clamp(260.0, 320.0);
  }

  Future<void> _issueNewPayload() async {
    final AppLocalizations l10n = context.l10n;
    if (!_checkInRepository.isOpen(_event.id)) {
      if (context.mounted) {
        setState(() {
          _payload = null;
          _qrLoadError = null;
        });
      }
      return;
    }
    if (context.mounted) {
      setState(() {
        _isIssuingPayload = true;
        _qrLoadError = null;
      });
    }
    try {
      final CheckInQrPayload next = await _checkInRepository.issuePayload(
        eventId: _event.id,
      );
      final EcoEvent? ev = _eventsRepository.findById(_event.id);
      if (ev != null && ev.activeCheckInSessionId != next.sessionId) {
        _eventsRepository.rotateCheckInSession(
          eventId: _event.id,
          sessionId: next.sessionId,
        );
      }
      if (context.mounted) {
        setState(() {
          _payload = next;
          _qrLoadError = null;
        });
        _syncCountdownNotifier();
      }
    } on AppError catch (e) {
      logEventsDiagnostic('organizer_checkin_qr_issue_failed');
      if (context.mounted) {
        final String msg = e.code == 'TOO_MANY_REQUESTS'
            ? l10n.eventsOrganizerQrRateLimited
            : (e.message.isNotEmpty
                  ? e.message
                  : l10n.eventsOrganizerQrLoadFailedGeneric);
        setState(() {
          _qrLoadError = msg;
          if (_remainingPayloadMs <= 0) {
            _payload = null;
          }
        });
      }
    } on Object {
      logEventsDiagnostic('organizer_checkin_qr_issue_failed');
      if (context.mounted) {
        setState(() {
          _qrLoadError = l10n.eventsOrganizerQrLoadFailedGeneric;
          if (_remainingPayloadMs <= 0) {
            _payload = null;
          }
        });
      }
    } finally {
      if (context.mounted) {
        setState(() => _isIssuingPayload = false);
      }
    }
  }

  void _startRefreshTicker() {
    _refreshTicker?.cancel();
    _refreshTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!context.mounted) {
        return;
      }
      if (!_event.isCheckInOpen) {
        if (_payload != null || _qrLoadError != null) {
          setState(() {
            _payload = null;
            _qrLoadError = null;
          });
          _syncCountdownNotifier();
        }
        return;
      }
      if (_isIssuingPayload) {
        setState(() {});
        return;
      }
      if (_payload == null && _qrLoadError == null && !_isIssuingPayload) {
        unawaited(_issueNewPayload());
        return;
      }
      if (_payload != null && _remainingPayloadMs <= 0) {
        unawaited(_issueNewPayload());
        return;
      }
      _syncCountdownNotifier();
    });
  }

  Future<void> _ensureSession() async {
    final EcoEvent? ev = _eventOrNull;
    if (ev == null) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    try {
      await _checkInRepository.ensureSession(event: ev);
      await _checkInRepository.refreshAttendees(ev.id);
      if (!context.mounted) {
        return;
      }
      await _issueNewPayload();
    } on AppError catch (e) {
      logEventsDiagnostic('organizer_checkin_session_setup_failed');
      if (!context.mounted) {
        return;
      }
      AppHaptics.warning();
      setState(() {
        _qrLoadError = e.message.isNotEmpty
            ? e.message
            : l10n.eventsOrganizerSessionSetupFailed;
      });
    } on Object {
      logEventsDiagnostic('organizer_checkin_session_setup_failed');
      if (!context.mounted) {
        return;
      }
      AppHaptics.warning();
      setState(() {
        _qrLoadError = l10n.eventsOrganizerSessionSetupFailed;
      });
    }
  }

  Future<void> _simulateCheckIn() async {
    AppHaptics.tap();
    if (_payload == null) {
      await _issueNewPayload();
      return;
    }
    const List<String> mockNames = <String>[
      'Ana M.',
      'Marko S.',
      'Elena K.',
      'Stefan D.',
      'Marija P.',
      'Nikola C.',
      'Sara V.',
    ];
    final List<String> available = mockNames
        .where((String name) {
          final String id = 'att_${name.toLowerCase().replaceAll(' ', '_')}';
          return !_attendees.any((CheckedInAttendee a) => a.id == id);
        })
        .toList(growable: false);
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
    final CheckInSubmissionResult result = await _checkInRepository.submitScan(
      rawPayload: _payload!.encode(),
      expectedEventId: _event.id,
      attendeeId: attendeeId,
      attendeeName: name,
    );
    if (!context.mounted) {
      return;
    }
    _showSubmissionFeedback(result, name);
    if (result.isSuccess ||
        result.isPendingConfirmation ||
        result.status == CheckInSubmissionStatus.alreadyCheckedIn) {
      await _issueNewPayload();
    }
  }

  Future<void> _addManualAttendee() async {
    final EventParticipantRow? picked =
        await showModalBottomSheet<EventParticipantRow?>(
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
                  child: ManualCheckInSheet(eventId: _event.id),
                ),
              ),
            );
          },
        );
    if (!context.mounted) {
      return;
    }
    if (picked == null) {
      return;
    }
    try {
      final ManualCheckInResult added = await _checkInRepository
          .markAttendeeCheckedIn(
            eventId: _event.id,
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
      await _issueNewPayload();
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
      AppSnack.show(
        context,
        message: e.message.isNotEmpty
            ? e.message
            : context.l10n.eventsOrganizerUnableCompleteEvent,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _removeAttendee(CheckedInAttendee attendee) async {
    // Synchronously hide before the first await so Dismissible doesn't
    // assert the widget is still in the tree on the next frame.
    setState(() => _dismissedAttendeeIds.add(attendee.id));

    final bool removed = await _checkInRepository.removeCheckedInAttendee(
      eventId: _event.id,
      attendeeId: attendee.id,
    );
    if (!context.mounted) {
      return;
    }
    if (!removed) {
      // Undo optimistic removal so the row reappears.
      setState(() => _dismissedAttendeeIds.remove(attendee.id));
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerCouldNotRemoveName(attendee.name),
        type: AppSnackType.warning,
      );
      return;
    }
    // Repo listener will rebuild and the attendee is gone from the source list;
    // clean up the optimistic set to avoid memory growth on long sessions.
    _dismissedAttendeeIds.remove(attendee.id);
    AppSnack.show(
      context,
      message: context.l10n.eventsOrganizerNameRemovedFromCheckIn(
        attendee.name,
      ),
      type: AppSnackType.warning,
    );
  }

  Future<void> _onInvalidateQrSessionChosen() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    final bool? ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext sheetCtx) {
        final AppLocalizations l10n = sheetCtx.l10n;
        final TextTheme sheetTextTheme = Theme.of(sheetCtx).textTheme;
        return ReportSheetScaffold(
          fitToContent: true,
          title: l10n.eventsOrganizerInvalidateQrTitle,
          subtitle: l10n.eventsOrganizerInvalidateQrSubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: l10n.commonClose,
            onTap: () {
              AppHaptics.tap();
              Navigator.of(sheetCtx).pop(false);
            },
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.tap();
                    Navigator.of(sheetCtx).pop(false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.commonCancel,
                    style: sheetTextTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: l10n.eventsOrganizerInvalidateQrTitle,
                enabled: true,
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(sheetCtx).pop(true);
                },
              ),
            ],
          ),
          child: const SizedBox.shrink(),
        );
      },
    );
    if (!mounted || ok != true) {
      return;
    }
    try {
      await _checkInRepository.rotateSession(_event.id);
      if (!mounted) {
        return;
      }
      await _issueNewPayload();
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerQrSessionRotated,
        type: AppSnackType.success,
      );
    } on AppError catch (_) {
      if (!mounted) {
        return;
      }
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerQrRotateFailed,
        type: AppSnackType.warning,
      );
    } on Object {
      if (!mounted) {
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

  Future<void> _copyQrToClipboard() async {
    AppHaptics.tap();
    final CheckInQrPayload? payload = _payload;
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

  bool _shouldShowOrganizerEndSoonBanner(EcoEvent event) {
    if (event.status != EcoEventStatus.inProgress) {
      return false;
    }
    final DateTime threshold =
        event.endDateTime.subtract(const Duration(minutes: 10));
    return !DateTime.now().isBefore(threshold);
  }

  void _openExtendEnd(EcoEvent event) {
    AppHaptics.tap();
    unawaited(
      showExtendEventEndSheet(
        context: context,
        event: event,
        eventsRepository: _eventsRepository,
      ),
    );
  }

  Future<void> _showOrganizerMoreActions() async {
    AppHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext sheetCtx) {
        final AppLocalizations sheetL10n = sheetCtx.l10n;
        return ReportSheetScaffold(
          fitToContent: true,
          title: sheetL10n.eventsOrganizerMoreSheetTitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: sheetL10n.commonClose,
            onTap: () {
              AppHaptics.tap();
              Navigator.of(sheetCtx).pop();
            },
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ReportActionTile(
                icon: CupertinoIcons.checkmark_seal_fill,
                title: sheetL10n.eventsOrganizerEndEvent,
                onTap: () {
                  AppHaptics.tap();
                  Navigator.of(sheetCtx).pop();
                  unawaited(_onEndEventChosenFromMenu());
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportActionTile(
                icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
                title: sheetL10n.eventsOrganizerInvalidateQrTitle,
                onTap: () {
                  AppHaptics.tap();
                  Navigator.of(sheetCtx).pop();
                  unawaited(_onInvalidateQrSessionChosen());
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportActionTile(
                icon: CupertinoIcons.doc_on_clipboard,
                title: sheetL10n.eventsOrganizerCopyQrText,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  unawaited(_copyQrToClipboard());
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportActionTile(
                icon: CupertinoIcons.xmark_circle_fill,
                title: sheetL10n.eventsOrganizerCancelEvent,
                tone: ReportSurfaceTone.danger,
                onTap: () {
                  AppHaptics.tap();
                  Navigator.of(sheetCtx).pop();
                  unawaited(_onCancelEventChosenFromMenu());
                },
              ),
              if (kDebugMode &&
                  _checkInRepository.supportsOrganizerSimulate) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                ReportActionTile(
                  icon: Icons.developer_mode_rounded,
                  title: sheetL10n.eventsOrganizerSimulateCheckInDev,
                  onTap: () {
                    AppHaptics.tap();
                    Navigator.of(sheetCtx).pop();
                    unawaited(_simulateCheckIn());
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _onEndEventChosenFromMenu() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    final bool ok = await _confirmEndEvent();
    if (!mounted || !ok) {
      return;
    }
    AppHaptics.tap();
    await _completeEndEventAfterConfirm();
  }

  Future<void> _onCancelEventChosenFromMenu() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    final bool ok = await _confirmCancelEvent();
    if (!mounted || !ok) {
      return;
    }
    AppHaptics.warning();
    await _completeCancelEventAfterConfirm();
  }

  Future<bool> _confirmEndEvent() async {
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext sheetCtx) {
        final AppLocalizations l10n = sheetCtx.l10n;
        final TextTheme sheetTextTheme = Theme.of(sheetCtx).textTheme;
        return ReportSheetScaffold(
          fitToContent: true,
          title: l10n.eventsOrganizerEndEventConfirmTitle,
          subtitle: l10n.eventsOrganizerEndEventConfirmMessage,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: l10n.commonClose,
            onTap: () {
              AppHaptics.tap();
              Navigator.of(sheetCtx).pop(false);
            },
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.tap();
                    Navigator.of(sheetCtx).pop(false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.eventsOrganizerEndEventKeepManaging,
                    style: sheetTextTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: l10n.eventsOrganizerEndEventConfirmAction,
                enabled: true,
                onPressed: () {
                  AppHaptics.tap();
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

  Future<bool> _confirmCancelEvent() async {
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext sheetCtx) {
        final AppLocalizations l10n = sheetCtx.l10n;
        final TextTheme sheetTextTheme = Theme.of(sheetCtx).textTheme;
        return ReportSheetScaffold(
          fitToContent: true,
          title: l10n.eventsOrganizerCancelEventConfirmTitle,
          subtitle: l10n.eventsOrganizerCancelEventConfirmMessage,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: l10n.commonClose,
            onTap: () {
              AppHaptics.tap();
              Navigator.of(sheetCtx).pop(false);
            },
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.tap();
                    Navigator.of(sheetCtx).pop(false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.eventsOrganizerCancelEventKeepEvent,
                    style: sheetTextTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    AppHaptics.warning();
                    Navigator.of(sheetCtx).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.accentDanger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.eventsOrganizerCancelEventConfirmAction,
                    style: AppTypography.buttonLabel.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: const SizedBox.shrink(),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _completeEndEventAfterConfirm() async {
    await _checkInRepository.closeSession(_event.id);
    final bool changed = await _eventsRepository.updateStatus(
      _event.id,
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
          checkedInCount: _attendees.length,
          participantCount: _event.participantCount,
          maxParticipants: _event.maxParticipants,
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
        if (!context.mounted) {
          return;
        }
        EventsNavigation.openCleanupEvidence(context, eventId: _event.id);
      });
    }
  }

  Future<void> _handlePauseResume() async {
    AppHaptics.tap();
    final bool isOpen = _event.isCheckInOpen;
    final bool changed = isOpen
        ? await _checkInRepository.pauseSession(_event.id)
        : await _checkInRepository.resumeSession(_event.id);
    if (!changed) {
      AppHaptics.warning();
      return;
    }
    if (!isOpen) {
      await _issueNewPayload();
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
  }

  Future<void> _completeCancelEventAfterConfirm() async {
    await _checkInRepository.closeSession(_event.id);
    final bool changed = await _eventsRepository.updateStatus(
      _event.id,
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

  void _showSubmissionFeedback(CheckInSubmissionResult result, String name) {
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

  void _onRepoChanged() {
    if (!context.mounted) {
      return;
    }
    void applyUpdate() {
      if (!context.mounted) {
        return;
      }
      setState(() {});
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
      return;
    }
    applyUpdate();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventsRepository.loadInitialIfNeeded();
    _eventsRepository.addListener(_onRepoChanged);
    _checkInRepository.addListener(_onRepoChanged);
    _connectCheckInWs();
    if (_eventOrNull != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_ensureSession());
      });
    }
    _startRefreshTicker();
    _startAttendeePollTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventsRepository.removeListener(_onRepoChanged);
    _checkInRepository.removeListener(_onRepoChanged);
    _refreshTicker?.cancel();
    _attendeePollTimer?.cancel();
    _countdownSeconds.dispose();
    _checkInWsSub?.cancel();
    _checkInWs?.dispose();
    if (ServiceLocator.instance.isInitialized) {
      unawaited(
        _organizerEndSoonLocal.dispose(
          ServiceLocator.instance.pushNotificationService,
        ),
      );
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final EcoEvent? ev = _eventOrNull;
      if (ev != null) {
        unawaited(_checkInRepository.refreshAttendees(ev.id));
      }
      _syncCountdownNotifier();
    }
  }

  void _connectCheckInWs() {
    final ServiceLocator sl = ServiceLocator.instance;
    _checkInWs = SocketCheckInStream(
      baseUrl: sl.config.apiBaseUrl,
      authState: sl.authState,
    );
    _checkInWsSub = _checkInWs!.stream.listen(_onCheckInWsEvent);
    _checkInWs!.connect(widget.eventId);
  }

  void _onCheckInWsEvent(CheckInStreamEvent event) {
    if (!mounted) return;
    if (event is CheckInRequestEvent && event.eventId == widget.eventId) {
      setState(() {
        _pendingConfirmQueue.add(event);
      });
      AppHaptics.medium();
      _showNextConfirmSheet();
      _refreshQrAfterVolunteerScan();
    }
  }

  /// Volunteer scan records a one-time JTI; issue a new QR so the next person does not reuse it.
  void _refreshQrAfterVolunteerScan() {
    if (!mounted || !_checkInRepository.isOpen(_event.id)) {
      return;
    }
    unawaited(_issueNewPayload());
  }

  void _showNextConfirmSheet() {
    if (_isShowingConfirmSheet || _pendingConfirmQueue.isEmpty || !mounted) {
      return;
    }
    _isShowingConfirmSheet = true;
    final CheckInRequestEvent request = _pendingConfirmQueue.removeAt(0);
    _showConfirmationBottomSheet(request);
  }

  void _showConfirmationBottomSheet(CheckInRequestEvent request) {
    final DateTime? expiresAt = DateTime.tryParse(request.expiresAt);
    final int timeoutMs = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inMilliseconds
        : 60000;
    Timer? autoExpireTimer;

    showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            autoExpireTimer?.cancel();
            if (timeoutMs > 0) {
              autoExpireTimer = Timer(
                Duration(milliseconds: timeoutMs.clamp(0, 120000)),
                () {
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop(false);
                  }
                },
              );
            }
            final String fullName = '${request.firstName} ${request.lastName}'
                .trim();
            return _CheckInConfirmSheet(
              fullName: fullName,
              avatarUrl: request.avatarUrl,
              avatarSeed: request.userId,
              isResolving: _isResolvingPending,
              onConfirm: () async {
                setSheetState(() => _isResolvingPending = true);
                try {
                  await _checkInRepository.resolvePendingCheckIn(
                    eventId: widget.eventId,
                    pendingId: request.pendingId,
                    approve: true,
                  );
                  AppHaptics.success();
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop(true);
                  }
                } on Object {
                  AppHaptics.warning();
                  if (ctx.mounted) {
                    AppSnack.show(
                      ctx,
                      message: ctx.l10n.eventsOrganizerConfirmExpired,
                      type: AppSnackType.warning,
                    );
                  }
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop(false);
                  }
                } finally {
                  _isResolvingPending = false;
                }
              },
              onReject: () async {
                setSheetState(() => _isResolvingPending = true);
                try {
                  await _checkInRepository.resolvePendingCheckIn(
                    eventId: widget.eventId,
                    pendingId: request.pendingId,
                    approve: false,
                  );
                } on Object {
                  // Expired or already resolved — dismiss silently.
                }
                _isResolvingPending = false;
                if (Navigator.of(ctx).canPop()) {
                  Navigator.of(ctx).pop(false);
                }
              },
            );
          },
        );
      },
    ).then((bool? approved) {
      autoExpireTimer?.cancel();
      _isShowingConfirmSheet = false;
      if (approved == true) {
        unawaited(_checkInRepository.refreshAttendees(widget.eventId));
      }
      if (mounted) {
        setState(() {});
        _showNextConfirmSheet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent? event = _eventOrNull;
    if (event == null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OrganizerCheckInHeader(title: context.l10n.eventsCheckInTitle),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      context.l10n.eventsEventNotFoundBody,
                      style: AppTypography.eventsBodyProse(
                        Theme.of(context).textTheme,
                      ).copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isOpen = event.isCheckInOpen;
    final List<CheckedInAttendee> attendees = _attendees;
    final double qrSize = _qrDisplaySize(context);
    final AppLocalizations l10n = context.l10n;

    if (ServiceLocator.instance.isInitialized) {
      unawaited(
        _organizerEndSoonLocal.sync(
          event: event,
          push: ServiceLocator.instance.pushNotificationService,
          l10n: l10n,
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            OrganizerCheckInHeader(
              title: event.title.isNotEmpty
                  ? event.title
                  : context.l10n.eventsCheckInTitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (event.status == EcoEventStatus.inProgress)
                    Semantics(
                      label: l10n.eventsOrganizerExtendEndSemantic,
                      button: true,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          CupertinoIcons.clock_fill,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () => _openExtendEnd(event),
                      ),
                    ),
                  Semantics(
                    label: isOpen
                        ? l10n.eventsOrganizerPauseCheckIn
                        : l10n.eventsOrganizerResumeCheckIn,
                    button: true,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: Icon(
                        isOpen
                            ? CupertinoIcons.pause_circle
                            : CupertinoIcons.play_circle,
                        color: AppColors.primaryDark,
                      ),
                      onPressed: () => unawaited(_handlePauseResume()),
                    ),
                  ),
                  Semantics(
                    label: l10n.eventsOrganizerMoreActionsSemantic,
                    button: true,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(
                        CupertinoIcons.ellipsis_circle,
                        color: AppColors.primaryDark,
                      ),
                      onPressed: () => unawaited(_showOrganizerMoreActions()),
                    ),
                  ),
                ],
              ),
            ),
            if (_shouldShowOrganizerEndSoonBanner(event)) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ReportInfoBanner(
                      title: l10n.eventsEndSoonBannerTitle,
                      message: l10n.eventsEndSoonBannerBody,
                      icon: CupertinoIcons.clock_fill,
                      tone: ReportSurfaceTone.accent,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => _openExtendEnd(event),
                        child: Text(l10n.eventsEndSoonBannerExtend),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusCard,
                              ),
                              border: Border.all(
                                color: AppColors.divider.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: AppSpacing.md,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: AppColors.shadowMedium,
                                  blurRadius: AppSpacing.lg,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.qrcode_viewfinder,
                                        size: 22,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        context
                                            .l10n
                                            .eventsOrganizerQrRefreshHelp,
                                        style: AppTypography.eventsBodyProse(
                                          textTheme,
                                        ).copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.l10n.eventsOrganizerHoldPhoneForScan,
                            style: AppTypography.eventsBodyMediumSecondary(
                              textTheme,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          RepaintBoundary(
                            child: ValueListenableBuilder<int>(
                              valueListenable: _countdownSeconds,
                              builder: (BuildContext context, int sec, Widget? _) {
                                return PulsingQRContainer(
                                  isActive: isOpen && _payload != null,
                                  pulseOnlyNearExpiry: true,
                                  remainingSecondsUntilExpiry:
                                      isOpen && _payload != null ? sec : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.panelBackground,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusCard,
                                      ),
                                      border: Border.all(
                                        color: AppColors.divider.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: AppColors.shadowLight,
                                          blurRadius: AppSpacing.md,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: AppColors.shadowMedium,
                                          blurRadius: AppSpacing.lg,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: AppMotion.standard,
                                      switchInCurve: AppMotion.emphasized,
                                      switchOutCurve: AppMotion.emphasized,
                                      child: !isOpen
                                          ? SizedBox(
                                              key: const ValueKey<String>(
                                                'qr_paused',
                                              ),
                                              width: qrSize,
                                              height: qrSize,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Icon(
                                                    CupertinoIcons
                                                        .pause_circle_fill,
                                                    size: 42,
                                                    color: AppColors.textMuted
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.sm,
                                                  ),
                                                  Text(
                                                    l10n.eventsOrganizerPausedLabel,
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: AppColors
                                                              .textMuted,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : _qrLoadError != null &&
                                                _payload == null
                                          ? SizedBox(
                                              key: ValueKey<String>(
                                                'qr_err_$_qrLoadError',
                                              ),
                                              width: qrSize,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Icon(
                                                    CupertinoIcons
                                                        .exclamationmark_circle,
                                                    size: 40,
                                                    color: AppColors
                                                        .accentWarningDark,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.sm,
                                                  ),
                                                  Text(
                                                    _qrLoadError!,
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.md,
                                                  ),
                                                  CupertinoButton(
                                                    onPressed: () {
                                                      AppHaptics.tap();
                                                      unawaited(
                                                        _issueNewPayload(),
                                                      );
                                                    },
                                                    child: Text(
                                                      l10n.eventsOrganizerQrRetry,
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .primaryDark,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : _payload != null
                                          ? TweenAnimationBuilder<double>(
                                              key: ValueKey<String>(
                                                _payload!.nonce,
                                              ),
                                              tween: Tween<double>(
                                                begin: 0.92,
                                                end: 1,
                                              ),
                                              duration:
                                                  MediaQuery.disableAnimationsOf(
                                                    context,
                                                  )
                                                  ? Duration.zero
                                                  : AppMotion.standard,
                                              curve: AppMotion.emphasized,
                                              builder:
                                                  (
                                                    BuildContext context,
                                                    double value,
                                                    Widget? child,
                                                  ) {
                                                    return Transform.scale(
                                                      scale: value,
                                                      child: Opacity(
                                                        opacity: value,
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                              child: EventCheckInQrCard(
                                                key: ValueKey<String>(
                                                  _payload!.nonce,
                                                ),
                                                payload: _payload!,
                                                qrSize: qrSize,
                                                semanticsLabel: l10n
                                                    .eventsOrganizerQrSemantics(
                                                      sec.clamp(0, 9999),
                                                    ),
                                                encodeErrorDescription: l10n
                                                    .eventsOrganizerQrEncodeError,
                                                retryLabel:
                                                    l10n.eventsOrganizerQrRetry,
                                                onRetryAfterEncodeError: () {
                                                  AppHaptics.tap();
                                                  unawaited(_issueNewPayload());
                                                },
                                              ),
                                            )
                                          : SizedBox(
                                              key: const ValueKey<String>(
                                                'qr_loading',
                                              ),
                                              width: qrSize,
                                              height: qrSize,
                                              child: const Center(
                                                child:
                                                    CupertinoActivityIndicator(
                                                      radius: 16,
                                                    ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (isOpen &&
                              _payload != null &&
                              _qrLoadError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    CupertinoIcons.exclamationmark_triangle,
                                    size: 14,
                                    color: AppColors.accentWarningDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      l10n.eventsOrganizerQrLoadFailedGeneric,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.accentWarningDark,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isOpen && _payload != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(
                                l10n.eventsOrganizerQrBrightnessHint,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      StatusPill(
                                        label: isOpen
                                            ? l10n.eventsOrganizerStatusOpen
                                            : l10n.eventsOrganizerStatusPaused,
                                        color: isOpen
                                            ? AppColors.primaryDark
                                            : AppColors.textMuted,
                                      ),
                                      if (isOpen &&
                                          _payload != null) ...<Widget>[
                                        const SizedBox(width: AppSpacing.sm),
                                        ValueListenableBuilder<int>(
                                          valueListenable: _countdownSeconds,
                                          builder: (BuildContext context, int sec, Widget? _) {
                                            return StatusPill(
                                              label: l10n
                                                  .eventsOrganizerRefreshInSeconds(
                                                    sec,
                                                  ),
                                              color: sec <= 3
                                                  ? AppColors.accentDanger
                                                  : sec <= 10
                                                  ? AppColors.accentWarningDark
                                                  : AppColors.textPrimary,
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                isOpen
                                    ? l10n.eventsOrganizerQrRefreshesWhenOpen
                                    : l10n.eventsOrganizerResumeForFreshQr,
                                style: AppTypography.eventsSupportingCaption(
                                  textTheme,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Semantics(
                                label:
                                    context.l10n.eventsOrganizerManualOverride,
                                button: true,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _addManualAttendee,
                                  child: Text(
                                    context.l10n.eventsOrganizerManualOverride,
                                    style: AppTypography.eventsCaptionStrong(
                                      textTheme,
                                      color: AppColors.primaryDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              if (_payload != null)
                                Semantics(
                                  label: context.l10n.eventsOrganizerCopyQrText,
                                  button: true,
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () =>
                                        unawaited(_copyQrToClipboard()),
                                    child: Text(
                                      context.l10n.eventsOrganizerCopyQrText,
                                      style: AppTypography.eventsCaptionStrong(
                                        textTheme,
                                        color: AppColors.primaryDark,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            context.l10n.eventsOrganizerCheckedInHeading,
                            style: AppTypography.eventsCalendarMonthTitle(
                              textTheme,
                            ).copyWith(color: AppColors.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Text(
                              '${attendees.length}',
                              style: AppTypography.badgeLabel.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (attendees.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                            horizontal: AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusCard,
                            ),
                            border: Border.all(
                              color: AppColors.divider.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              Icon(
                                CupertinoIcons.person_2,
                                size: 44,
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                context.l10n.eventsOrganizerEmptyListTitle,
                                style: AppTypography.eventsFeedSectionTitle(
                                  textTheme,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                context.l10n.eventsOrganizerEmptyListSubtitle,
                                style: AppTypography.eventsSupportingCaption(
                                  textTheme,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((
                          BuildContext context,
                          int index,
                        ) {
                          final CheckedInAttendee attendee = attendees[index];
                          return CheckedInRow(
                            attendee: attendee,
                            onRemove: () =>
                                unawaited(_removeAttendee(attendee)),
                          );
                        }, childCount: attendees.length),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal sheet shown to the organizer when a volunteer scans the QR and needs confirmation.
class _CheckInConfirmSheet extends StatelessWidget {
  const _CheckInConfirmSheet({
    required this.fullName,
    required this.avatarSeed,
    this.avatarUrl,
    required this.isResolving,
    required this.onConfirm,
    required this.onReject,
  });

  final String fullName;
  final String avatarSeed;
  final String? avatarUrl;
  final bool isResolving;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          UserAvatarCircle(
            displayName: fullName,
            imageUrl: avatarUrl,
            size: 80,
            seed: avatarSeed,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.eventsOrganizerConfirmTitle,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            fullName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.eventsOrganizerConfirmSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: isResolving ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(l10n.eventsOrganizerConfirmReject),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: isResolving ? null : onConfirm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                  child: isResolving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.eventsOrganizerConfirmApprove,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
