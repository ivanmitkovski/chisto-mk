import 'dart:math';

import 'package:chisto_mobile/features/events/data/check_in_local_cache.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:flutter/foundation.dart';

class InMemoryCheckInRepository extends ChangeNotifier implements CheckInRepository {
  InMemoryCheckInRepository._();

  static final InMemoryCheckInRepository instance = InMemoryCheckInRepository._();

  static const int _ttlMs = 45000;
  final Random _random = Random();
  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
  final CheckInLocalCache _localCache = const CheckInLocalCache();

  final Map<String, _CheckInSessionState> _sessions = <String, _CheckInSessionState>{};
  bool _isHydrating = false;
  bool _didHydrate = false;

  @override
  Duration get payloadTtl => const Duration(milliseconds: _ttlMs);

  @visibleForTesting
  void reset() {
    _sessions.clear();
    _didHydrate = false;
    _isHydrating = false;
    _localCache.clear();
    notifyListeners();
  }

  void _hydrateIfNeeded() {
    if (_didHydrate || _isHydrating) {
      return;
    }
    _didHydrate = true;
    _isHydrating = true;
    _localCache.readSessions().then((List<PersistedCheckInSession> sessions) {
      for (final PersistedCheckInSession session in sessions) {
        final _CheckInSessionState state = _CheckInSessionState(
          sessionId: session.sessionId,
          isOpen: session.isOpen,
        );
        state.attendees.addAll(session.attendees);
        _sessions[session.eventId] = state;
        _syncCheckInToEvents(eventId: session.eventId, state: state);
      }
      notifyListeners();
    }).whenComplete(() {
      _isHydrating = false;
    });
  }

  @override
  String ensureSession({
    required EcoEvent event,
    bool openIfNeeded = true,
  }) {
    _hydrateIfNeeded();
    final _CheckInSessionState state = _sessions.putIfAbsent(
      event.id,
      () => _CheckInSessionState(
        sessionId: event.activeCheckInSessionId ?? _newSessionId(event.id),
        isOpen: openIfNeeded,
      ),
    );

    if (openIfNeeded) {
      state.isOpen = true;
    }

    _eventsRepository.rotateCheckInSession(
      eventId: event.id,
      sessionId: state.sessionId,
    );
    _eventsRepository.setCheckInOpen(eventId: event.id, isOpen: state.isOpen);
    _persistSessions();
    return state.sessionId;
  }

  @override
  CheckInQrPayload issuePayload({
    required String eventId,
  }) {
    _hydrateIfNeeded();
    final _CheckInSessionState state = _sessions.putIfAbsent(
      eventId,
      () => _CheckInSessionState(
        sessionId: _newSessionId(eventId),
        isOpen: true,
      ),
    );

    final int now = DateTime.now().millisecondsSinceEpoch;
    _purgeExpiredNonces(state, now);
    final String nonce = '${now}_${_random.nextInt(1000000)}';
    state.issuedNonces[nonce] = now;
    _persistSessions();

    return CheckInQrPayload(
      eventId: eventId,
      sessionId: state.sessionId,
      nonce: nonce,
      issuedAtMs: now,
    );
  }

  @override
  CheckInSubmissionResult submitScan({
    required String rawPayload,
    required String expectedEventId,
    required String attendeeId,
    required String attendeeName,
  }) {
    _hydrateIfNeeded();
    final CheckInQrPayload? payload = CheckInQrPayload.tryParse(rawPayload);
    if (payload == null) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.invalidFormat,
      );
    }
    if (expectedEventId.isEmpty || attendeeId.isEmpty || attendeeName.isEmpty) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.invalidFormat,
      );
    }
    if (payload.eventId != expectedEventId) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.wrongEvent,
      );
    }

    final _CheckInSessionState? state = _sessions[payload.eventId];
    if (state == null || !state.isOpen || state.sessionId != payload.sessionId) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.sessionClosed,
      );
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    _purgeExpiredNonces(state, now);
    if (state.consumedNonces.contains(payload.nonce)) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.replayDetected,
      );
    }
    final int issuedAt = state.issuedNonces[payload.nonce] ?? -1;
    if (issuedAt < 0 || (now - payload.issuedAtMs) > _ttlMs) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.sessionExpired,
      );
    }

    if (state.attendees.any((CheckedInAttendee e) => e.id == attendeeId)) {
      return const CheckInSubmissionResult(
        status: CheckInSubmissionStatus.alreadyCheckedIn,
      );
    }

    state.consumedNonces.add(payload.nonce);
    state.issuedNonces.remove(payload.nonce);
    final DateTime checkedInAt = DateTime.now();
    state.attendees.add(
      CheckedInAttendee(
        id: attendeeId,
        name: attendeeName,
        checkedInAt: checkedInAt,
      ),
    );
    _syncCheckInToEvents(eventId: payload.eventId, state: state);
    _persistSessions();
    notifyListeners();

    return CheckInSubmissionResult(
      status: CheckInSubmissionStatus.success,
      checkedInAt: checkedInAt,
    );
  }

  @override
  bool pauseSession(String eventId) {
    _hydrateIfNeeded();
    final _CheckInSessionState? state = _sessions[eventId];
    if (state == null || !state.isOpen) {
      return false;
    }
    state.isOpen = false;
    _eventsRepository.setCheckInOpen(eventId: eventId, isOpen: false);
    _persistSessions();
    notifyListeners();
    return true;
  }

  @override
  bool resumeSession(String eventId) {
    _hydrateIfNeeded();
    final _CheckInSessionState state = _sessions.putIfAbsent(
      eventId,
      () => _CheckInSessionState(
        sessionId: _newSessionId(eventId),
        isOpen: true,
      ),
    );
    if (state.isOpen) {
      return false;
    }
    state.isOpen = true;
    _eventsRepository.setCheckInOpen(eventId: eventId, isOpen: true);
    _persistSessions();
    notifyListeners();
    return true;
  }

  @override
  bool closeSession(String eventId) {
    _hydrateIfNeeded();
    final _CheckInSessionState? state = _sessions[eventId];
    if (state == null) {
      return false;
    }
    state.isOpen = false;
    state.issuedNonces.clear();
    _eventsRepository.setCheckInOpen(eventId: eventId, isOpen: false);
    _persistSessions();
    notifyListeners();
    return true;
  }

  @override
  bool markAttendeeCheckedIn({
    required String eventId,
    required String attendeeId,
    required String attendeeName,
  }) {
    _hydrateIfNeeded();
    if (eventId.isEmpty || attendeeId.isEmpty || attendeeName.isEmpty) {
      return false;
    }
    final _CheckInSessionState state = _sessions.putIfAbsent(
      eventId,
      () => _CheckInSessionState(
        sessionId: _newSessionId(eventId),
        isOpen: true,
      ),
    );
    final bool exists = state.attendees.any((CheckedInAttendee e) => e.id == attendeeId);
    if (exists) {
      return false;
    }
    state.attendees.add(
      CheckedInAttendee(
        id: attendeeId,
        name: attendeeName,
        checkedInAt: DateTime.now(),
      ),
    );
    _syncCheckInToEvents(eventId: eventId, state: state);
    _persistSessions();
    notifyListeners();
    return true;
  }

  @override
  bool removeCheckedInAttendee({
    required String eventId,
    required String attendeeId,
  }) {
    _hydrateIfNeeded();
    final _CheckInSessionState? state = _sessions[eventId];
    if (state == null) {
      return false;
    }
    final int before = state.attendees.length;
    state.attendees.removeWhere((CheckedInAttendee e) => e.id == attendeeId);
    if (state.attendees.length == before) {
      return false;
    }
    _syncCheckInToEvents(eventId: eventId, state: state);
    _persistSessions();
    notifyListeners();
    return true;
  }

  @override
  List<CheckedInAttendee> checkedInAttendees(String eventId) {
    _hydrateIfNeeded();
    return List<CheckedInAttendee>.unmodifiable(
      _sessions[eventId]?.attendees ?? const <CheckedInAttendee>[],
    );
  }

  @override
  int checkedInCount(String eventId) {
    _hydrateIfNeeded();
    return _sessions[eventId]?.attendees.length ?? 0;
  }

  @override
  bool isOpen(String eventId) {
    _hydrateIfNeeded();
    return _sessions[eventId]?.isOpen ?? false;
  }

  String _newSessionId(String eventId) {
    return 'sess_${DateTime.now().millisecondsSinceEpoch}_${eventId}_${_random.nextInt(100000)}';
  }

  void _syncCheckInToEvents({
    required String eventId,
    required _CheckInSessionState state,
  }) {
    _eventsRepository.setCheckedInCount(
      eventId: eventId,
      checkedInCount: state.attendees.length,
    );
    final bool currentUserCheckedIn = state.attendees.any(
      (CheckedInAttendee attendee) => attendee.id == CurrentUser.id,
    );
    _eventsRepository.setAttendeeCheckInStatus(
      eventId: eventId,
      status: currentUserCheckedIn
          ? AttendeeCheckInStatus.checkedIn
          : AttendeeCheckInStatus.notCheckedIn,
      checkedInAt: currentUserCheckedIn
          ? state.attendees
              .firstWhere((CheckedInAttendee e) => e.id == CurrentUser.id)
              .checkedInAt
          : null,
    );
  }

  void _persistSessions() {
    final List<PersistedCheckInSession> sessions = _sessions.entries
        .map(
          (MapEntry<String, _CheckInSessionState> entry) =>
              PersistedCheckInSession(
                eventId: entry.key,
                sessionId: entry.value.sessionId,
                isOpen: entry.value.isOpen,
                attendees: List<CheckedInAttendee>.unmodifiable(
                  entry.value.attendees,
                ),
              ),
        )
        .toList(growable: false);
    _localCache.writeSessions(sessions);
  }

  void _purgeExpiredNonces(_CheckInSessionState state, int nowMs) {
    final List<String> expired = <String>[];
    state.issuedNonces.forEach((String nonce, int issuedAtMs) {
      if (nowMs - issuedAtMs > _ttlMs) {
        expired.add(nonce);
      }
    });
    for (final String nonce in expired) {
      state.issuedNonces.remove(nonce);
    }
  }
}

class _CheckInSessionState {
  _CheckInSessionState({
    required this.sessionId,
    required this.isOpen,
  });

  final String sessionId;
  bool isOpen;
  final Map<String, int> issuedNonces = <String, int>{};
  final Set<String> consumedNonces = <String>{};
  final List<CheckedInAttendee> attendees = <CheckedInAttendee>[];
}
