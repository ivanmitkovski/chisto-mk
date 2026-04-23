import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/features/events/data/chat/chat_outbox_sync.dart';
import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_queue.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_service.dart';
import 'package:chisto_mobile/features/events/data/field_mode_queue.dart';
import 'package:chisto_mobile/features/events/data/field_mode_sync_service.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';

/// High-level state for the offline-work hub (no PII; counts only).
enum OfflineWorkSyncPhase {
  idle,
  syncing,
  failed,
  needsAttention,
}

class EventOfflineWorkSnapshot {
  const EventOfflineWorkSnapshot({
    required this.checkInPending,
    required this.fieldPending,
    required this.chatPending,
    required this.chatFailed,
    required this.phase,
    this.lastDiagnosticCode,
  });

  factory EventOfflineWorkSnapshot.empty() => const EventOfflineWorkSnapshot(
        checkInPending: 0,
        fieldPending: 0,
        chatPending: 0,
        chatFailed: 0,
        phase: OfflineWorkSyncPhase.idle,
        lastDiagnosticCode: null,
      );

  final int checkInPending;
  final int fieldPending;
  final int chatPending;
  final int chatFailed;
  final OfflineWorkSyncPhase phase;
  final String? lastDiagnosticCode;

  int get totalWorkItems => checkInPending + fieldPending + chatPending + chatFailed;
}

class _LifecycleBridge with WidgetsBindingObserver {
  _LifecycleBridge(this.onResumed);

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

/// Serializes offline drains (check-in redeem → field batch → chat outbox) after
/// reconnect / resume / manual sync.
class EventOfflineWorkCoordinator {
  EventOfflineWorkCoordinator._();

  static final EventOfflineWorkCoordinator instance = EventOfflineWorkCoordinator._();

  final ValueNotifier<EventOfflineWorkSnapshot> snapshot =
      ValueNotifier<EventOfflineWorkSnapshot>(EventOfflineWorkSnapshot.empty());

  bool _started = false;
  Timer? _debounce;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  _LifecycleBridge? _lifecycle;
  Future<void> _drainChain = Future<void>.value();

  /// Debounced schedule (collapse connectivity bursts).
  void scheduleDrain() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 550), () {
      _drainChain = _drainChain.then((_) => _runDrain());
    });
  }

  /// Immediate drain (e.g. hub "Sync now").
  Future<void> requestManualDrain() async {
    _debounce?.cancel();
    _drainChain = _drainChain.then((_) => _runDrain());
    await _drainChain;
  }

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await refreshSnapshot();
    _connectivitySub = ConnectivityGate.watch().listen((
      List<ConnectivityResult> results,
    ) {
      if (ConnectivityGate.isOnline(results)) {
        scheduleDrain();
      }
    });
    _lifecycle = _LifecycleBridge(scheduleDrain);
    WidgetsBinding.instance.addObserver(_lifecycle!);
    if (ServiceLocator.instance.isInitialized) {
      ServiceLocator.instance.authState.addListener(_onAuthChanged);
    }
    scheduleDrain();
  }

  void _onAuthChanged() {
    unawaited(refreshSnapshot());
    if (ServiceLocator.instance.isInitialized &&
        ServiceLocator.instance.authState.isAuthenticated) {
      scheduleDrain();
    }
  }

  void dispose() {
    if (!_started) {
      return;
    }
    _started = false;
    _debounce?.cancel();
    _debounce = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    if (_lifecycle != null) {
      WidgetsBinding.instance.removeObserver(_lifecycle!);
      _lifecycle = null;
    }
    if (ServiceLocator.instance.isInitialized) {
      ServiceLocator.instance.authState.removeListener(_onAuthChanged);
    }
    snapshot.value = EventOfflineWorkSnapshot.empty();
    _drainChain = Future<void>.value();
  }

  Future<void> refreshSnapshot() async {
    if (!ServiceLocator.instance.isInitialized) {
      snapshot.value = EventOfflineWorkSnapshot.empty();
      return;
    }
    final ServiceLocator sl = ServiceLocator.instance;
    if (!sl.authState.isAuthenticated) {
      snapshot.value = EventOfflineWorkSnapshot.empty();
      return;
    }
    final int checkIn =
        (await CheckInSyncQueue.instance.peek()).length;
    final int field = (await FieldModeQueue.instance.pendingRows()).length;
    final int chatP = await ChatOutboxStore.shared.totalPendingCount();
    final int chatF = await ChatOutboxStore.shared.totalFailedCount();
    final OfflineWorkSyncPhase phase = chatF > 0
        ? OfflineWorkSyncPhase.needsAttention
        : OfflineWorkSyncPhase.idle;
    snapshot.value = EventOfflineWorkSnapshot(
      checkInPending: checkIn,
      fieldPending: field,
      chatPending: chatP,
      chatFailed: chatF,
      phase: phase,
      lastDiagnosticCode: null,
    );
  }

  Future<void> _runDrain() async {
    if (!_started) {
      return;
    }
    final ServiceLocator sl = ServiceLocator.instance;
    if (!sl.isInitialized || !sl.authState.isAuthenticated) {
      await refreshSnapshot();
      return;
    }
    final List<ConnectivityResult> reachability = await ConnectivityGate.check();
    if (!ConnectivityGate.isOnline(reachability)) {
      await refreshSnapshot();
      return;
    }

    final EventOfflineWorkSnapshot before = snapshot.value;
    snapshot.value = EventOfflineWorkSnapshot(
      checkInPending: before.checkInPending,
      fieldPending: before.fieldPending,
      chatPending: before.chatPending,
      chatFailed: before.chatFailed,
      phase: OfflineWorkSyncPhase.syncing,
      lastDiagnosticCode: null,
    );
    logEventsDiagnostic('offline_work_drain_started');
    try {
      await CheckInSyncService.drainPendingQueue();
      await FieldModeSyncService(client: sl.apiClient).syncPendingRows();
      for (int i = 0; i < 50; i++) {
        final ChatOutboxEntry? entry =
            await ChatOutboxStore.shared.peekNextGlobally();
        if (entry == null) {
          break;
        }
        final ChatOutboxFlushResult res = await ChatOutboxSync.flushOne(
          repo: sl.eventChatRepository,
          store: ChatOutboxStore.shared,
          entry: entry,
        );
        if (res.kind == ChatOutboxFlushKind.sent) {
          continue;
        }
        if (res.kind == ChatOutboxFlushKind.terminalFailed) {
          continue;
        }
        await Future<void>.delayed(
          ChatOutboxSync.retryDelayAfterAttempt(entry.attemptCount + 1),
        );
        break;
      }
    } on Object catch (_) {
      logEventsDiagnostic('offline_work_drain_failed', detail: 'phase=exception');
      await refreshSnapshot();
      final EventOfflineWorkSnapshot s = snapshot.value;
      snapshot.value = EventOfflineWorkSnapshot(
        checkInPending: s.checkInPending,
        fieldPending: s.fieldPending,
        chatPending: s.chatPending,
        chatFailed: s.chatFailed,
        phase: OfflineWorkSyncPhase.failed,
        lastDiagnosticCode: 'offline_work_drain_failed',
      );
      return;
    }
    await refreshSnapshot();
    final EventOfflineWorkSnapshot after = snapshot.value;
    logEventsDiagnostic(
      'offline_work_drain_complete',
      detail:
          'ci=${after.checkInPending},fd=${after.fieldPending},ctp=${after.chatPending},cf=${after.chatFailed}',
    );
  }
}
