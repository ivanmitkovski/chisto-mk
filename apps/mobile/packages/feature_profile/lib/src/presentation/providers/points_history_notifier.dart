import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigator_key.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_profile/src/domain/models/points_history_page.dart';
import 'package:feature_profile/src/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<PointsHistoryPage> _fetchInitialPage() async {
    try {
      return await ref
          .read(profileRepositoryProvider)
          .getPointsHistory(limit: 30);
    } on AppError {
      rethrow;
    } catch (e) {
      throw AppError.network(cause: e);
    }
  }

  void _showRefreshFailedSnack() {
    final BuildContext? ctx = appRootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    AppSnack.show(
      ctx,
      message: ctx.l10n.profileRefreshFailedSnack,
      type: AppSnackType.warning,
    );
  }

  /// First load and full-screen retry when there is no cached list yet.
  Future<void> loadInitial() async {
    final bool hadContent = state.entries.isNotEmpty;
    if (!hadContent) {
      state = const PointsHistoryUiState(phase: PointsHistoryPhase.loading);
    }
    try {
      final PointsHistoryPage page = await _fetchInitialPage();
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.ready,
        entries: List<PointsHistoryEntry>.of(page.items),
        milestones: List<PointsHistoryMilestone>.of(page.milestones),
        nextCursor: page.nextCursor,
      );
    } on AppError catch (e) {
      if (hadContent) {
        _showRefreshFailedSnack();
        return;
      }
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.error,
        pageError: e,
      );
    }
  }

  /// Pull-to-refresh: keep the current screen visible (no skeleton cross-fade).
  Future<void> refresh() async {
    final List<PointsHistoryEntry> previousEntries =
        List<PointsHistoryEntry>.of(state.entries);
    final List<PointsHistoryMilestone> previousMilestones =
        List<PointsHistoryMilestone>.of(state.milestones);
    final String? previousCursor = state.nextCursor;
    final bool keepCurrentVisible = state.phase == PointsHistoryPhase.ready;

    if (!keepCurrentVisible) {
      state = const PointsHistoryUiState(phase: PointsHistoryPhase.loading);
    }

    try {
      final PointsHistoryPage page = await _fetchInitialPage();
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.ready,
        entries: List<PointsHistoryEntry>.of(page.items),
        milestones: List<PointsHistoryMilestone>.of(page.milestones),
        nextCursor: page.nextCursor,
      );
    } on AppError catch (e) {
      if (keepCurrentVisible) {
        state = PointsHistoryUiState(
          phase: PointsHistoryPhase.ready,
          entries: previousEntries,
          milestones: previousMilestones,
          nextCursor: previousCursor,
        );
        _showRefreshFailedSnack();
        return;
      }
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.error,
        pageError: e,
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
      final PointsHistoryPage page = await ref
          .read(profileRepositoryProvider)
          .getPointsHistory(limit: 30, cursor: cursor);
      state = PointsHistoryUiState(
        phase: PointsHistoryPhase.ready,
        entries: <PointsHistoryEntry>[...previousEntries, ...page.items],
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
