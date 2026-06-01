import 'dart:async';

import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/connectivity/app_connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feature_home/src/data/engagement_outbox_store.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';

/// Drains [EngagementOutboxStore] when the device is online and the user is signed in.
class EngagementOutboxCoordinator
    extends OutboxCoordinatorBase<EngagementOutboxEntry> {
  EngagementOutboxCoordinator._(this._sites, this._auth)
    : super(
        backoff: OutboxBackoffScheduler(
          onRetry: () {
            final EngagementOutboxCoordinator? inst =
                EngagementOutboxCoordinator._instance;
            if (inst == null) {
              return;
            }
            unawaited(AppConnectivity.check().then(inst._flushIfOnline));
          },
        ),
      );

  final SitesRepository _sites;
  final AuthState _auth;

  static EngagementOutboxCoordinator? _instance;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static Future<void> start({
    required SitesRepository sitesRepository,
    required AuthState authState,
  }) async {
    if (_instance != null) {
      return;
    }
    _instance = EngagementOutboxCoordinator._(sitesRepository, authState);
    await _instance!._flushIfOnline(await AppConnectivity.check());
    _subscription = AppConnectivity.watch().listen((
      List<ConnectivityResult> results,
    ) {
      unawaited(_instance?._flushIfOnline(results));
    });
  }

  static void dispose() {
    _instance?.backoff.dispose();
    _subscription?.cancel();
    _subscription = null;
    _instance = null;
  }

  Future<void> _flushIfOnline(List<ConnectivityResult> results) async {
    if (!AppConnectivity.isOnline(results)) {
      return;
    }
    if (!_auth.isAuthenticated) {
      return;
    }
    await drainPending();
  }

  @override
  Future<List<EngagementOutboxEntry>> peekPending() =>
      EngagementOutboxStore.instance.peek();

  @override
  Future<OutboxFlushDisposition> flushEntry(EngagementOutboxEntry e) async {
    try {
      switch (e.kind) {
        case EngagementOutboxKind.upvote:
          await _sites.upvoteSite(e.siteId);
        case EngagementOutboxKind.removeUpvote:
          await _sites.removeSiteUpvote(e.siteId);
        case EngagementOutboxKind.save:
          await _sites.saveSite(e.siteId);
        case EngagementOutboxKind.unsave:
          await _sites.unsaveSite(e.siteId);
      }
      await EngagementOutboxStore.instance.removeById(e.id);
      return OutboxFlushDisposition.completed;
    } on AppError catch (err) {
      if (err.retryable) {
        await EngagementOutboxStore.instance.recordRetryableFlushFailure(e.id);
        return OutboxFlushDisposition.retryableSkipped;
      }
      await EngagementOutboxStore.instance.removeById(e.id);
      return OutboxFlushDisposition.terminalRemoved;
    } catch (_) {
      return OutboxFlushDisposition.retryableSkipped;
    }
  }
}
