import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/data/engagement_outbox_store.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Drains [EngagementOutboxStore] when the device is online and the user is signed in.
class EngagementOutboxCoordinator {
  EngagementOutboxCoordinator._(this._sites, this._auth);

  final SitesRepository _sites;
  final AuthState _auth;

  static EngagementOutboxCoordinator? _instance;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static Timer? _backoffTimer;
  static int _backoffMs = 2000;

  static bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }
    return results.any(
      (ConnectivityResult r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  static Future<void> start({
    required SitesRepository sitesRepository,
    required AuthState authState,
  }) async {
    if (_instance != null) {
      return;
    }
    _instance = EngagementOutboxCoordinator._(sitesRepository, authState);
    await _instance!._flushIfOnline(await Connectivity().checkConnectivity());
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        unawaited(_instance?._flushIfOnline(results));
      },
    );
  }

  static void dispose() {
    _backoffTimer?.cancel();
    _backoffTimer = null;
    _backoffMs = 2000;
    _subscription?.cancel();
    _subscription = null;
    _instance = null;
  }

  static void _scheduleBackoffRetry() {
    _backoffTimer?.cancel();
    _backoffTimer = Timer(Duration(milliseconds: _backoffMs), () {
      _backoffMs = math.min(_backoffMs * 2, 60000);
      final EngagementOutboxCoordinator? inst = _instance;
      if (inst == null) {
        return;
      }
      unawaited(
        Connectivity().checkConnectivity().then(inst._flushIfOnline),
      );
    });
  }

  Future<void> _flushIfOnline(List<ConnectivityResult> results) async {
    if (!_isOnline(results)) {
      return;
    }
    if (!_auth.isAuthenticated) {
      return;
    }
    final List<EngagementOutboxEntry> pending =
        await EngagementOutboxStore.instance.peek();
    bool hadRetryableSkip = false;
    for (final EngagementOutboxEntry e in pending) {
      try {
        switch (e.kind) {
          case EngagementOutboxKind.upvote:
            await _sites.upvoteSite(e.siteId);
            break;
          case EngagementOutboxKind.removeUpvote:
            await _sites.removeSiteUpvote(e.siteId);
            break;
          case EngagementOutboxKind.save:
            await _sites.saveSite(e.siteId);
            break;
          case EngagementOutboxKind.unsave:
            await _sites.unsaveSite(e.siteId);
            break;
        }
        await EngagementOutboxStore.instance.removeById(e.id);
      } on AppError catch (err) {
        if (err.retryable) {
          await EngagementOutboxStore.instance.recordRetryableFlushFailure(e.id);
          hadRetryableSkip = true;
          continue;
        }
        await EngagementOutboxStore.instance.removeById(e.id);
      } catch (_) {
        // Deliberate: one bad entry must not block the rest of the outbox.
        hadRetryableSkip = true;
        continue;
      }
    }
    if (hadRetryableSkip) {
      _scheduleBackoffRetry();
    } else {
      _backoffMs = 2000;
    }
  }
}
