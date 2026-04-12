import 'dart:async';

import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/check_in_offline_redeem.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_queue.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton that drains the [CheckInSyncQueue] whenever connectivity is restored.
///
/// Start once in ServiceLocator via [CheckInSyncService.start].
/// The service listens for connectivity changes and retries queued check-ins.
/// Entries that return [CheckInSubmissionStatus.replayDetected] or
/// [CheckInSubmissionStatus.alreadyCheckedIn] are treated as already synced
/// and silently removed.
class CheckInSyncService {
  CheckInSyncService._({
    required ApiClient client,
    required EventsRepository eventsRepository,
    required CheckInRepository checkInRepository,
  })  : _client = client,
        _eventsRepository = eventsRepository,
        _checkInRepository = checkInRepository;

  static CheckInSyncService? _instance;

  final ApiClient _client;
  final EventsRepository _eventsRepository;
  // ignore: unused_field — reserved for future attendee list refresh after sync
  final CheckInRepository _checkInRepository;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _draining = false;

  /// Initialises and starts the service. Idempotent — safe to call more than once.
  static Future<void> start({
    required ApiClient client,
    required EventsRepository eventsRepository,
    required CheckInRepository checkInRepository,
  }) async {
    if (_instance != null) return;
    _instance = CheckInSyncService._(
      client: client,
      eventsRepository: eventsRepository,
      checkInRepository: checkInRepository,
    );
    await _instance!._init();
  }

  Future<void> _init() async {
    // Drain immediately in case we're already online.
    unawaited(_drainIfOnline());

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final bool online = results.any(
          (ConnectivityResult r) => r != ConnectivityResult.none,
        );
        if (online) {
          await _drainIfOnline();
        }
      },
    );
  }

  Future<void> _drainIfOnline() async {
    if (_draining) return;
    _draining = true;
    try {
      await _drain();
    } finally {
      _draining = false;
    }
  }

  Future<void> _drain() async {
    final List<CheckInQueueEntry> entries = await CheckInSyncQueue.instance.peek();
    if (entries.isEmpty) return;

    for (final CheckInQueueEntry entry in entries) {
      try {
        await _redeemEntry(entry);
      } on Object {
        // Network failure — leave the entry in the queue for the next drain.
        break;
      }
    }
  }

  Future<void> _redeemEntry(CheckInQueueEntry entry) {
    return redeemOfflineCheckInEntry(
      client: _client,
      eventsRepository: _eventsRepository,
      entry: entry,
    );
  }

  /// Cancels the connectivity listener and allows [start] again (e.g. after tests reset DI).
  static void dispose() {
    _instance?._tearDown();
    _instance = null;
  }

  void _tearDown() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
