import 'dart:async';

import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/check_in_offline_redeem.dart';
import 'package:chisto_mobile/features/events/data/check_in_sync_queue.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';

/// Singleton that drains the [CheckInSyncQueue] when the app-level offline-work
/// coordinator schedules work (connectivity restored, app resume, or manual sync).
///
/// Start once in ServiceLocator via [CheckInSyncService.start].
/// Entries that return [CheckInSubmissionStatus.replayDetected] or
/// [CheckInSubmissionStatus.alreadyCheckedIn] are treated as already synced
/// and silently removed.
class CheckInSyncService {
  CheckInSyncService._({
    required ApiClient client,
    required EventsRepository eventsRepository,
    required CheckInRepository checkInRepository,
  }) : _client = client,
       _eventsRepository = eventsRepository,
       _checkInRepository = checkInRepository;

  static CheckInSyncService? _instance;

  final ApiClient _client;
  final EventsRepository _eventsRepository;
  final CheckInRepository _checkInRepository;

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
    // One immediate attempt; ongoing drains are owned by [EventOfflineWorkCoordinator].
    unawaited(_drainIfOnline());
  }

  /// Drains the offline redeem queue once (serialized with the coordinator).
  static Future<void> drainPendingQueue() async {
    final CheckInSyncService? svc = _instance;
    if (svc == null) {
      return;
    }
    await svc._drainIfOnline();
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
    final List<CheckInQueueEntry> entries = await CheckInSyncQueue.instance
        .peek();
    if (entries.isEmpty) return;

    for (final CheckInQueueEntry entry in entries) {
      try {
        await _redeemEntry(entry);
      } on Object catch (_) {
        logEventsDiagnostic('check_in_sync_entry_failed');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _redeemEntry(CheckInQueueEntry entry) {
    return redeemOfflineCheckInEntry(
      client: _client,
      eventsRepository: _eventsRepository,
      entry: entry,
      checkInRepository: _checkInRepository,
    );
  }

  /// Cancels the connectivity listener and allows [start] again (e.g. after tests reset DI).
  static void dispose() {
    _instance?._tearDown();
    _instance = null;
  }

  void _tearDown() {}
}
