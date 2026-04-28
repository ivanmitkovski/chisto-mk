import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/data/engagement_outbox_store.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Outcome of an engagement mutation (upvote / save) for UI messaging.
class SiteEngagementOutcome {
  const SiteEngagementOutcome._(this.kind, {this.error});

  const SiteEngagementOutcome.success() : this._(SiteEngagementOutcomeKind.success);

  const SiteEngagementOutcome.notAuthenticated()
      : this._(SiteEngagementOutcomeKind.notAuthenticated);

  const SiteEngagementOutcome.throttled()
      : this._(SiteEngagementOutcomeKind.throttled);

  const SiteEngagementOutcome.failureUnknown()
      : this._(SiteEngagementOutcomeKind.failure, error: null);

  const SiteEngagementOutcome.queuedOffline()
      : this._(SiteEngagementOutcomeKind.queuedOffline);

  SiteEngagementOutcome.failureWithError(AppError err)
      : this._(SiteEngagementOutcomeKind.failure, error: err);

  final SiteEngagementOutcomeKind kind;
  final AppError? error;

  bool get isSuccess => kind == SiteEngagementOutcomeKind.success;
}

enum SiteEngagementOutcomeKind {
  success,
  notAuthenticated,
  throttled,
  failure,
  queuedOffline,
}

@immutable
class SiteEngagementState {
  const SiteEngagementState({
    required this.siteId,
    required this.isUpvoted,
    required this.upvoteCount,
    required this.commentCount,
    required this.shareCount,
    required this.isSaved,
    this.isUpvoteInFlight = false,
    this.isSaveInFlight = false,
  });

  final String siteId;
  final bool isUpvoted;
  final int upvoteCount;
  final int commentCount;
  final int shareCount;
  final bool isSaved;
  final bool isUpvoteInFlight;
  final bool isSaveInFlight;

  factory SiteEngagementState.initial(String siteId) => SiteEngagementState(
        siteId: siteId,
        isUpvoted: false,
        upvoteCount: 0,
        commentCount: 0,
        shareCount: 0,
        isSaved: false,
        isSaveInFlight: false,
      );

  factory SiteEngagementState.fromSite(PollutionSite site) => SiteEngagementState(
        siteId: site.id,
        isUpvoted: site.isUpvotedByMe,
        upvoteCount: site.score,
        commentCount: site.commentCount,
        shareCount: site.shareCount,
        isSaved: site.isSavedByMe,
        isSaveInFlight: false,
      );

  SiteEngagementState copyWith({
    bool? isUpvoted,
    int? upvoteCount,
    int? commentCount,
    int? shareCount,
    bool? isSaved,
    bool? isUpvoteInFlight,
    bool? isSaveInFlight,
  }) {
    return SiteEngagementState(
      siteId: siteId,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isSaved: isSaved ?? this.isSaved,
      isUpvoteInFlight: isUpvoteInFlight ?? this.isUpvoteInFlight,
      isSaveInFlight: isSaveInFlight ?? this.isSaveInFlight,
    );
  }

  SiteEngagementState applySnapshot(EngagementSnapshot snap) {
    return SiteEngagementState(
      siteId: siteId,
      isUpvoted: snap.isUpvotedByMe,
      upvoteCount: snap.upvotesCount,
      commentCount: snap.commentsCount,
      shareCount: snap.sharesCount,
      isSaved: snap.isSavedByMe,
      isUpvoteInFlight: isUpvoteInFlight,
      isSaveInFlight: false,
    );
  }
}

final siteEngagementNotifierProvider = StateNotifierProvider.autoDispose
    .family<SiteEngagementNotifier, SiteEngagementState, String>(
  (Ref ref, String siteId) {
    return SiteEngagementNotifier(ref, siteId);
  },
);

class SiteEngagementNotifier extends StateNotifier<SiteEngagementState> {
  SiteEngagementNotifier(this._ref, this._siteId)
      : super(SiteEngagementState.initial(_siteId));

  final Ref _ref;
  final String _siteId;

  bool _upvoteInFlight = false;
  bool _saveInFlight = false;
  DateTime? _lastUpvoteAt;
  DateTime? _lastSaveAt;

  SitesRepository get _repo => _ref.read(sitesRepositoryProvider);

  void hydrate(PollutionSite site) {
    if (site.id != _siteId) {
      return;
    }
    state = SiteEngagementState.fromSite(site);
  }

  void setCommentCount(int count) {
    if (state.siteId != _siteId) {
      return;
    }
    state = state.copyWith(commentCount: count);
  }

  void setShareCount(int count) {
    if (state.siteId != _siteId) {
      return;
    }
    state = state.copyWith(shareCount: count);
  }

  void applySnapshot(EngagementSnapshot snap) {
    state = state.applySnapshot(snap);
  }

  Future<EngagementSnapshot> _upvoteCall(bool nextUpvoted) {
    return nextUpvoted ? _repo.upvoteSite(_siteId) : _repo.removeSiteUpvote(_siteId);
  }

  Future<EngagementSnapshot> _saveCall(bool nextSaved) {
    return nextSaved ? _repo.saveSite(_siteId) : _repo.unsaveSite(_siteId);
  }

  /// One silent retry for transient failures (network / 5xx) after a short backoff.
  Future<EngagementSnapshot> _withSingleRetryOnRetryable(
    Future<EngagementSnapshot> Function() call,
  ) async {
    try {
      return await call();
    } on AppError catch (e) {
      if (!e.retryable) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      return await call();
    }
  }

  Future<SiteEngagementOutcome> toggleUpvote() async {
    if (!ServiceLocator.instance.authState.isAuthenticated) {
      return const SiteEngagementOutcome.notAuthenticated();
    }
    final DateTime now = DateTime.now();
    if (_lastUpvoteAt != null &&
        now.difference(_lastUpvoteAt!) < const Duration(milliseconds: 550)) {
      return const SiteEngagementOutcome.throttled();
    }
    _lastUpvoteAt = now;
    if (_upvoteInFlight) {
      return const SiteEngagementOutcome.throttled();
    }
    _upvoteInFlight = true;
    final SiteEngagementState previous = state;
    final bool nextUpvoted = !state.isUpvoted;
    state = state.copyWith(
      isUpvoted: nextUpvoted,
      upvoteCount: (state.upvoteCount + (nextUpvoted ? 1 : -1)).clamp(0, 999999),
      isUpvoteInFlight: true,
    );
    try {
      final EngagementSnapshot snap =
          await _withSingleRetryOnRetryable(() => _upvoteCall(nextUpvoted));
      state = state.applySnapshot(snap);
      return const SiteEngagementOutcome.success();
    } on AppError catch (e) {
      state = previous;
      final bool queueableOffline = e.retryable &&
          e.code != 'TOO_MANY_REQUESTS' &&
          (e.code == 'NETWORK_ERROR' || e.code == 'TIMEOUT' || e.code == 'SERVER_ERROR');
      if (queueableOffline) {
        await EngagementOutboxStore.enqueueUpvoteIntent(
          siteId: _siteId,
          wantUpvoted: nextUpvoted,
        );
        return const SiteEngagementOutcome.queuedOffline();
      }
      return SiteEngagementOutcome.failureWithError(e);
    } catch (_) {
      state = previous;
      return const SiteEngagementOutcome.failureUnknown();
    } finally {
      _upvoteInFlight = false;
      if (state.siteId == _siteId) {
        state = state.copyWith(isUpvoteInFlight: false);
      }
    }
  }

  Future<SiteEngagementOutcome> toggleSave() async {
    if (!ServiceLocator.instance.authState.isAuthenticated) {
      return const SiteEngagementOutcome.notAuthenticated();
    }
    final DateTime now = DateTime.now();
    if (_lastSaveAt != null &&
        now.difference(_lastSaveAt!) < const Duration(milliseconds: 550)) {
      return const SiteEngagementOutcome.throttled();
    }
    _lastSaveAt = now;
    if (_saveInFlight) {
      return const SiteEngagementOutcome.throttled();
    }
    _saveInFlight = true;
    final SiteEngagementState previous = state;
    final bool nextSaved = !state.isSaved;
    state = state.copyWith(isSaved: nextSaved, isSaveInFlight: true);
    try {
      final EngagementSnapshot snap =
          await _withSingleRetryOnRetryable(() => _saveCall(nextSaved));
      state = state.applySnapshot(snap);
      return const SiteEngagementOutcome.success();
    } on AppError catch (e) {
      final bool queueableOffline = e.retryable &&
          e.code != 'TOO_MANY_REQUESTS' &&
          (e.code == 'NETWORK_ERROR' || e.code == 'TIMEOUT' || e.code == 'SERVER_ERROR');
      if (queueableOffline) {
        await EngagementOutboxStore.enqueueSaveIntent(
          siteId: _siteId,
          wantSaved: nextSaved,
        );
        // Keep optimistic [isSaved]; feed list must match via [patchSiteSaved].
        return const SiteEngagementOutcome.queuedOffline();
      }
      state = previous;
      return SiteEngagementOutcome.failureWithError(e);
    } catch (_) {
      state = previous;
      return const SiteEngagementOutcome.failureUnknown();
    } finally {
      _saveInFlight = false;
      if (state.siteId == _siteId) {
        state = state.copyWith(isSaveInFlight: false);
      }
    }
  }
}
