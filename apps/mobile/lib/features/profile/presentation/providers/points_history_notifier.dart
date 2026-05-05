import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_providers.dart';

enum PointsHistoryPhase { loading, error, ready }

@immutable
class PointsHistoryUiState {
  const PointsHistoryUiState({
    this.phase = PointsHistoryPhase.loading,
    this.pageError,
    this.entries = const <PointsHistoryEntry>[],
    this.milestones = const <PointsHistoryMilestone>[],
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final PointsHistoryPhase phase;
  final AppError? pageError;
  final List<PointsHistoryEntry> entries;
  final List<PointsHistoryMilestone> milestones;
  final String? nextCursor;
  final bool loadingMore;
  final AppError? loadMoreError;
}

class PointsHistoryNotifier extends AutoDisposeNotifier<PointsHistoryUiState> {
  @override
  PointsHistoryUiState build() =>
      const PointsHistoryUiState(phase: PointsHistoryPhase.loading);

  Future<void> loadInitial() async {
    state = const PointsHistoryUiState(phase: PointsHistoryPhase.loading);
    try {
      final PointsHistoryPage page =
          await ref.read(profileRepositoryProvider).getPointsHistory(limit: 30);
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.ready,
        entries: List<PointsHistoryEntry>.of(page.items),
        milestones: List<PointsHistoryMilestone>.of(page.milestones),
        nextCursor: page.nextCursor,
      );
    } on AppError catch (e) {
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.error,
        pageError: e,
      );
    } catch (e) {
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.error,
        pageError: AppError.network(cause: e),
      );
    }
  }

  Future<void> loadMore() async {
    final String? cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    final List<PointsHistoryEntry> previousEntries =
        List<PointsHistoryEntry>.of(state.entries);
    final List<PointsHistoryMilestone> previousMilestones =
        List<PointsHistoryMilestone>.of(state.milestones);
    final String? previousCursor = state.nextCursor;
    state = PointsHistoryUiState(
      phase: PointsHistoryPhase.ready,
      entries: previousEntries,
      milestones: previousMilestones,
      nextCursor: previousCursor,
      loadingMore: true,
    );
    try {
      final PointsHistoryPage page =
          await ref.read(profileRepositoryProvider).getPointsHistory(
                limit: 30,
                cursor: cursor,
              );
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.ready,
        entries: <PointsHistoryEntry>[
          ...previousEntries,
          ...page.items,
        ],
        milestones: previousMilestones,
        nextCursor: page.nextCursor,
      );
    } on AppError catch (e) {
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.ready,
        entries: previousEntries,
        milestones: previousMilestones,
        nextCursor: previousCursor,
        loadMoreError: e,
      );
    } catch (e) {
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.ready,
        entries: previousEntries,
        milestones: previousMilestones,
        nextCursor: previousCursor,
        loadMoreError: AppError.network(cause: e),
      );
    }
  }

}

final pointsHistoryNotifierProvider =
    AutoDisposeNotifierProvider<PointsHistoryNotifier, PointsHistoryUiState>(
  PointsHistoryNotifier.new,
);
