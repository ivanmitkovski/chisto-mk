import 'dart:async';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/features/home/data/site_history_repository.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final siteHistoryRepositoryProvider = Provider<SiteHistoryRepository>((Ref ref) {
  return SiteHistoryRepository(ref.watch(appBootstrapProvider).apiClient);
});

final siteHistoryTabEnabledProvider = Provider<bool>((Ref ref) {
  return ref.watch(appBootstrapProvider).config.siteHistoryTabEnabled;
});

@immutable
class SiteHistoryState {
  const SiteHistoryState({
    this.items = const <SiteHistoryEntry>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.nextBeforeId,
  });

  final List<SiteHistoryEntry> items;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final String? nextBeforeId;

  bool get hasMore => nextBeforeId != null && nextBeforeId!.isNotEmpty;

  SiteHistoryState copyWith({
    List<SiteHistoryEntry>? items,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    String? nextBeforeId,
    bool clearError = false,
  }) {
    return SiteHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      nextBeforeId: nextBeforeId ?? this.nextBeforeId,
    );
  }
}

final siteHistoryProvider = StateNotifierProvider.autoDispose
    .family<SiteHistoryNotifier, SiteHistoryState, String>(
  (Ref ref, String siteId) => SiteHistoryNotifier(ref, siteId),
);

class SiteHistoryNotifier extends StateNotifier<SiteHistoryState> {
  SiteHistoryNotifier(this._ref, this._siteId) : super(const SiteHistoryState(isLoading: true)) {
    _listenRealtime();
    unawaited(refresh());
  }

  final Ref _ref;
  final String _siteId;
  StreamSubscription<dynamic>? _sseSub;
  Timer? _debounce;

  SiteHistoryRepository get _repo => _ref.read(siteHistoryRepositoryProvider);

  void _listenRealtime() {
    _sseSub = AppBootstrap.instance.mapRealtimeService.events.listen((event) {
      if (event.siteId != _siteId) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        AppLog.verbose('site_history: SSE refresh siteId=$_siteId');
        unawaited(refresh());
      });
    });
    _ref.onDispose(() {
      _debounce?.cancel();
      unawaited(_sseSub?.cancel());
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.fetchHistory(_siteId);
      state = SiteHistoryState(
        items: page.items,
        nextBeforeId: page.nextBeforeId,
      );
    } catch (e, st) {
      AppLog.warn('site_history: refresh failed', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _repo.fetchHistory(
        _siteId,
        beforeId: state.nextBeforeId,
      );
      state = state.copyWith(
        items: <SiteHistoryEntry>[...state.items, ...page.items],
        isLoadingMore: false,
        nextBeforeId: page.nextBeforeId,
      );
    } catch (e, st) {
      AppLog.warn('site_history: loadMore failed', error: e, stackTrace: st);
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}
