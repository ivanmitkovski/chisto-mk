import 'dart:async';

import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:feature_home/src/data/site_history_repository.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/domain/repositories/site_history_repository_port.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final siteHistoryRepositoryProvider = Provider<SiteHistoryRepositoryPort>((
  Ref ref,
) {
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
    this.summary,
  });

  final List<SiteHistoryEntry> items;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final String? nextBeforeId;
  final SiteHistorySummary? summary;

  bool get hasMore => nextBeforeId != null && nextBeforeId!.isNotEmpty;

  SiteHistoryState copyWith({
    List<SiteHistoryEntry>? items,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    String? nextBeforeId,
    SiteHistorySummary? summary,
    bool clearError = false,
  }) {
    return SiteHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      nextBeforeId: nextBeforeId ?? this.nextBeforeId,
      summary: summary ?? this.summary,
    );
  }
}

final siteHistoryProvider = NotifierProvider.autoDispose
    .family<SiteHistoryNotifier, SiteHistoryState, String>(
      SiteHistoryNotifier.new,
    );

class SiteHistoryNotifier
    extends AutoDisposeFamilyNotifier<SiteHistoryState, String> {
  StreamSubscription<dynamic>? _sseSub;
  Timer? _debounce;
  int _fetchGeneration = 0;

  String get _siteId => arg;

  SiteHistoryRepositoryPort get _repo =>
      ref.read(siteHistoryRepositoryProvider);

  @override
  SiteHistoryState build(String siteId) {
    _listenRealtime();
    ref.onDispose(() {
      _fetchGeneration++;
      _debounce?.cancel();
      unawaited(_sseSub?.cancel());
    });
    return const SiteHistoryState(isLoading: true);
  }

  void _listenRealtime() {
    _sseSub = ref.read(mapRealtimeServiceProvider).events.listen((event) {
      if (event.siteId != _siteId) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        AppLog.verbose('site_history: SSE refresh siteId=$_siteId');
        unawaited(refresh(silent: true));
      });
    });
  }

  Future<void> loadInitial() async {
    await refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    final int generation = ++_fetchGeneration;
    final bool showSkeleton = !silent && state.items.isEmpty;
    if (showSkeleton) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else if (!silent) {
      state = state.copyWith(clearError: true);
    }

    final KeepAliveLink keepAlive = ref.keepAlive();
    try {
      final page = await _repo.fetchHistory(_siteId);
      if (generation != _fetchGeneration) return;
      state = SiteHistoryState(
        items: page.items,
        nextBeforeId: page.nextBeforeId,
        summary: page.summary,
      );
    } catch (e, st) {
      if (generation != _fetchGeneration) return;
      AppLog.warn('site_history: refresh failed', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e);
    } finally {
      keepAlive.close();
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final int generation = _fetchGeneration;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _repo.fetchHistory(
        _siteId,
        beforeId: state.nextBeforeId,
      );
      if (generation != _fetchGeneration) return;
      state = state.copyWith(
        items: _dedupeHistoryItems(<SiteHistoryEntry>[
          ...state.items,
          ...page.items,
        ]),
        isLoadingMore: false,
        nextBeforeId: page.nextBeforeId,
      );
    } catch (e, st) {
      if (generation != _fetchGeneration) return;
      AppLog.warn('site_history: loadMore failed', error: e, stackTrace: st);
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

List<SiteHistoryEntry> _dedupeHistoryItems(List<SiteHistoryEntry> items) {
  final Set<String> seenIds = <String>{};
  final List<SiteHistoryEntry> deduped = <SiteHistoryEntry>[];
  for (final SiteHistoryEntry entry in items) {
    if (seenIds.add(entry.id)) {
      deduped.add(entry);
    }
  }
  return deduped;
}

@visibleForTesting
List<SiteHistoryEntry> dedupeSiteHistoryItemsForTesting(
  List<SiteHistoryEntry> items,
) => _dedupeHistoryItems(items);
