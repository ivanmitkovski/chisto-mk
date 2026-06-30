import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/domain/models/check_in_payload.dart';
import 'package:feature_events/src/domain/repositories/check_in_repository.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/utils/events_diagnostic_log.dart';
import 'package:flutter/foundation.dart';

/// Issues rotating check-in QR payloads, keeps countdown UI in sync, and
/// auto-refreshes when the payload TTL expires.
class OrganizerCheckInQrSessionController {
  OrganizerCheckInQrSessionController({
    required this.eventId,
    required this.checkInRepository,
    required this.eventsRepository,
    required this.isMounted,
    required this.isCheckInOpen,
    required this.readL10n,
    required this.onStateChanged,
  });

  final String eventId;
  final CheckInRepository checkInRepository;
  final EventsRepository eventsRepository;
  final bool Function() isMounted;
  final bool Function() isCheckInOpen;
  final AppLocalizations Function() readL10n;
  final VoidCallback onStateChanged;

  CheckInQrPayload? payload;
  String? qrLoadError;
  bool isIssuingPayload = false;

  /// Decouples QR countdown UI from full-screen [setState] on every tick.
  final ValueNotifier<int> countdownSeconds = ValueNotifier<int>(0);

  Timer? _refreshTicker;

  int get _deadlineMs {
    final CheckInQrPayload? current = payload;
    if (current == null) {
      return 0;
    }
    return current.expiresAtMs ??
        current.issuedAtMs + checkInRepository.payloadTtl.inMilliseconds;
  }

  int get _remainingPayloadMs {
    if (payload == null) {
      return 0;
    }
    final int left = _deadlineMs - DateTime.now().millisecondsSinceEpoch;
    return left.clamp(0, 86400000);
  }

  int get _remainingPayloadSeconds => (_remainingPayloadMs / 1000).ceil();

  void dispose() {
    _refreshTicker?.cancel();
    _refreshTicker = null;
    countdownSeconds.dispose();
  }

  void syncCountdownNotifier() {
    if (payload == null) {
      if (countdownSeconds.value != 0) {
        countdownSeconds.value = 0;
      }
      return;
    }
    final int next = _remainingPayloadSeconds;
    if (next != countdownSeconds.value) {
      countdownSeconds.value = next;
    }
  }

  Future<void> issueNewPayload() async {
    final AppLocalizations l10n = readL10n();
    if (!checkInRepository.isOpen(eventId)) {
      if (isMounted()) {
        payload = null;
        qrLoadError = null;
        onStateChanged();
      }
      return;
    }
    if (isMounted()) {
      isIssuingPayload = true;
      qrLoadError = null;
      onStateChanged();
    }
    try {
      final CheckInQrPayload next = await checkInRepository.issuePayload(
        eventId: eventId,
      );
      final String? activeSessionId = eventsRepository
          .findById(eventId)
          ?.activeCheckInSessionId;
      if (activeSessionId != null && activeSessionId != next.sessionId) {
        eventsRepository.rotateCheckInSession(
          eventId: eventId,
          sessionId: next.sessionId,
        );
      }
      if (isMounted()) {
        payload = next;
        qrLoadError = null;
        onStateChanged();
        syncCountdownNotifier();
      }
    } on AppError catch (e) {
      logEventsDiagnostic('organizer_checkin_qr_issue_failed');
      if (isMounted()) {
        final String msg = e.code == 'TOO_MANY_REQUESTS'
            ? l10n.eventsOrganizerQrRateLimited
            : localizedAppErrorMessage(l10n, e);
        qrLoadError = msg;
        if (_remainingPayloadMs <= 0) {
          payload = null;
        }
        onStateChanged();
      }
    } on Object {
      logEventsDiagnostic('organizer_checkin_qr_issue_failed');
      if (isMounted()) {
        qrLoadError = l10n.eventsOrganizerQrLoadFailedGeneric;
        if (_remainingPayloadMs <= 0) {
          payload = null;
        }
        onStateChanged();
      }
    } finally {
      if (isMounted()) {
        isIssuingPayload = false;
        onStateChanged();
      }
    }
  }

  void setLoadError(String message) {
    qrLoadError = message;
    onStateChanged();
  }

  void startRefreshTicker() {
    _refreshTicker?.cancel();
    _refreshTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isMounted()) {
        return;
      }
      if (!isCheckInOpen()) {
        if (payload != null || qrLoadError != null) {
          payload = null;
          qrLoadError = null;
          onStateChanged();
          syncCountdownNotifier();
        }
        return;
      }
      if (isIssuingPayload) {
        onStateChanged();
        return;
      }
      if (payload == null && qrLoadError == null && !isIssuingPayload) {
        unawaited(issueNewPayload());
        return;
      }
      if (payload != null && _remainingPayloadMs <= 0) {
        unawaited(issueNewPayload());
        return;
      }
      syncCountdownNotifier();
    });
  }
}
