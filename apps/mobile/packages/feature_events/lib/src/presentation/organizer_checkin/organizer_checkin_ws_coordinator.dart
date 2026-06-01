part of 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_screen.dart';

/// WebSocket listener and queued confirmation sheets for volunteer check-ins.
class OrganizerCheckInWsCoordinator {
  OrganizerCheckInWsCoordinator({
    required this.eventId,
    required this.checkInRepository,
    required this.isMounted,
    required this.readContext,
    required this.onStateChanged,
    required this.onVolunteerScan,
  });

  final String eventId;
  final CheckInRepository checkInRepository;
  final bool Function() isMounted;
  final BuildContext Function() readContext;
  final VoidCallback onStateChanged;
  final VoidCallback onVolunteerScan;

  SocketCheckInStream? _checkInWs;
  StreamSubscription<CheckInStreamEvent>? _checkInWsSub;
  final List<CheckInRequestEvent> _pendingConfirmQueue =
      <CheckInRequestEvent>[];
  bool _isShowingConfirmSheet = false;
  bool _isResolvingPending = false;

  void connect(AppBootstrap sl) {
    _checkInWs = SocketCheckInStream(
      baseUrl: sl.config.apiBaseUrl,
      authState: sl.authState,
    );
    _checkInWsSub = _checkInWs!.stream.listen(_onCheckInWsEvent);
    _checkInWs!.connect(eventId);
  }

  void dispose() {
    _checkInWsSub?.cancel();
    _checkInWs?.dispose();
    _checkInWsSub = null;
    _checkInWs = null;
  }

  void _onCheckInWsEvent(CheckInStreamEvent event) {
    if (!isMounted()) {
      return;
    }
    if (event is CheckInRequestEvent && event.eventId == eventId) {
      _pendingConfirmQueue.add(event);
      onStateChanged();
      AppHaptics.medium();
      _showNextConfirmSheet();
      onVolunteerScan();
    }
  }

  void _showNextConfirmSheet() {
    if (_isShowingConfirmSheet ||
        _pendingConfirmQueue.isEmpty ||
        !isMounted()) {
      return;
    }
    _isShowingConfirmSheet = true;
    final CheckInRequestEvent request = _pendingConfirmQueue.removeAt(0);
    _showConfirmationBottomSheet(request);
  }

  void _showConfirmationBottomSheet(CheckInRequestEvent request) {
    final BuildContext context = readContext();
    final DateTime? expiresAt = DateTime.tryParse(request.expiresAt);
    final int timeoutMs = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inMilliseconds
        : 60000;
    Timer? autoExpireTimer;

    showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.transparent,
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
                  await checkInRepository.resolvePendingCheckIn(
                    eventId: eventId,
                    pendingId: request.pendingId,
                    approve: true,
                  );
                  AppHaptics.success();
                  if (!ctx.mounted) {
                    return;
                  }
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop(true);
                  }
                } on Object {
                  AppHaptics.warning();
                  if (!ctx.mounted) {
                    return;
                  }
                  AppSnack.show(
                    ctx,
                    message: ctx.l10n.eventsOrganizerConfirmExpired,
                    type: AppSnackType.warning,
                  );
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
                  await checkInRepository.resolvePendingCheckIn(
                    eventId: eventId,
                    pendingId: request.pendingId,
                    approve: false,
                  );
                } on Object {
                  // Expired or already resolved — dismiss silently.
                }
                _isResolvingPending = false;
                if (!ctx.mounted) {
                  return;
                }
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
      if (approved ?? false) {
        unawaited(checkInRepository.refreshAttendees(eventId));
      }
      if (isMounted()) {
        onStateChanged();
        _showNextConfirmSheet();
      }
    });
  }
}
