import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_providers.dart';

/// Loads and refreshes the weekly leaderboard for the profile rankings screen.
class WeeklyRankingsNotifier
    extends AutoDisposeAsyncNotifier<WeeklyRankingsResult> {
  @override
  Future<WeeklyRankingsResult> build() => _fetch();

  /// Re-fetches rankings (pull-to-refresh, retry after error).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<WeeklyRankingsResult> _fetch() async {
    try {
      return await ref
          .read(profileRepositoryProvider)
          .getWeeklyRankings(limit: 50);
    } on AppError {
      rethrow;
    } catch (e) {
      throw AppError.network(cause: e);
    }
  }
}

final weeklyRankingsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    WeeklyRankingsNotifier,
    WeeklyRankingsResult>(WeeklyRankingsNotifier.new);
