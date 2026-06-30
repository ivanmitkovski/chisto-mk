part of 'package:feature_events/src/presentation/screens/attendee_qr_scanner_screen.dart';

extension QrScannerPendingFlow on _AttendeeQrScannerScreenState {
  // --- Pending confirmation flow (volunteer side) ---

  void _startPendingConfirmationFlow(CheckInSubmissionResult result) {
    final AppBootstrap sl = ref.read(appBootstrapProvider);
    _checkInWs = SocketCheckInStream(
      baseUrl: sl.config.apiBaseUrl,
      authState: sl.authState,
    );
    _checkInWsSub = _checkInWs!.stream.listen(_onPendingWsEvent);
    _checkInWs!.connect(widget.eventId);

    // Client-side timeout based on server expiresAt (fallback 60s).
    final int timeoutMs = result.pendingExpiresAt != null
        ? result.pendingExpiresAt!
              .difference(DateTime.now())
              .inMilliseconds
              .clamp(5000, 120000)
        : 60000;
    _pendingTimeoutTimer = Timer(Duration(milliseconds: timeoutMs), () {
      if (!mounted || !_pendingConfirmation) return;
      _onPendingExpired();
    });

    // Fallback poll while waiting on organizer (tightens when WS is down).
    _restartPendingPollTimer(fast: false);
  }

  void _restartPendingPollTimer({required bool fast}) {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = Timer.periodic(Duration(seconds: fast ? 1 : 3), (_) {
      if (!mounted || !_pendingConfirmation || _pendingId == null) return;
      unawaited(_pollPendingStatus());
    });
  }

  void _onPendingWsEvent(CheckInStreamEvent event) {
    if (!mounted || !_pendingConfirmation) return;
    if (event is CheckInConnectionChanged) {
      if (event.status != CheckInWsConnectionStatus.connected) {
        unawaited(_pollPendingStatus());
        _restartPendingPollTimer(fast: true);
      } else {
        _restartPendingPollTimer(fast: false);
      }
      return;
    }
    if (event is CheckInConnectionGaveUp) {
      _cleanupPendingState();
      rebuildState(() {
        _pendingConfirmation = false;
        _feedback = context.l10n.checkInConnectionTimeout;
      });
      unawaited(_resumeCameraAfterLifecycle());
      _resumeScanLineAnimationIfNeeded();
      return;
    }
    if (event is CheckInConfirmedEvent && event.pendingId == _pendingId) {
      _onPendingConfirmed(
        checkedInAt: DateTime.tryParse(event.checkedInAt),
        pointsAwarded: event.pointsAwarded,
      );
    } else if (event is CheckInRejectedEvent && event.pendingId == _pendingId) {
      _onPendingRejected();
    }
  }

  Future<void> _pollPendingStatus() async {
    if (_pendingId == null) return;
    final String? status = await _checkInRepository.pollPendingStatus(
      eventId: widget.eventId,
      pendingId: _pendingId!,
    );
    if (!mounted || !_pendingConfirmation) return;
    if (status == 'expired') {
      _onPendingExpired();
    }
  }

  void _onPendingConfirmed({DateTime? checkedInAt, int pointsAwarded = 0}) {
    _cleanupPendingState();
    _markAttendeeCheckedInOnEventsStore(checkedInAt);
    rebuildState(() {
      _pendingConfirmation = false;
      _scanned = true;
      _checkedInAt = checkedInAt;
      _checkInPointsAwarded = pointsAwarded;
    });
    widget.onCheckInSuccess?.call();
  }

  void _onPendingRejected() {
    _cleanupPendingState();
    rebuildState(() {
      _pendingConfirmation = false;
      _feedback = context.l10n.eventsVolunteerRejected;
    });
    unawaited(_resumeCameraAfterLifecycle());
    _resumeScanLineAnimationIfNeeded();
  }

  void _onPendingExpired() {
    _cleanupPendingState();
    rebuildState(() {
      _pendingConfirmation = false;
      _feedback = context.l10n.eventsVolunteerExpired;
    });
    unawaited(_resumeCameraAfterLifecycle());
    _resumeScanLineAnimationIfNeeded();
  }

  void _cleanupPendingState() {
    _pendingTimeoutTimer?.cancel();
    _pendingTimeoutTimer = null;
    _pendingPollTimer?.cancel();
    _pendingPollTimer = null;
    _checkInWsSub?.cancel();
    _checkInWsSub = null;
    _checkInWs?.dispose();
    _checkInWs = null;
    _pendingId = null;
  }
}
