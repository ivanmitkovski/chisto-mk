import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/weekly_rankings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/testing_profile_repository.dart';

void main() {
  group('WeeklyRankingsNotifier', () {
    test('build loads rankings via repository', () async {
      final WeeklyRankingsResult payload = WeeklyRankingsResult(
        weekStartsAt: '2026-01-01T00:00:00.000Z',
        weekEndsAt: '2026-01-07T23:59:59.000Z',
        entries: const <WeeklyLeaderboardEntry>[
          WeeklyLeaderboardEntry(
            rank: 1,
            userId: 'a',
            displayName: 'A',
            weeklyPoints: 10,
            isCurrentUser: true,
          ),
        ],
        myRank: 1,
        myWeeklyPoints: 10,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            TestingProfileRepository(
              getMeImpl: () async => throw UnimplementedError(),
              getWeeklyRankingsImpl: ({int limit = 50}) async => payload,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final WeeklyRankingsResult v =
          await container.read(weeklyRankingsNotifierProvider.future);
      expect(v.entries.length, 1);
      expect(v.entries.first.displayName, 'A');
    });

    test('refresh re-fetches after error', () async {
      int calls = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            TestingProfileRepository(
              getMeImpl: () async => throw UnimplementedError(),
              getWeeklyRankingsImpl: ({int limit = 50}) async {
                calls++;
                if (calls == 1) {
                  throw AppError.unknown();
                }
                return WeeklyRankingsResult(
                  weekStartsAt: '2026-01-01T00:00:00.000Z',
                  weekEndsAt: '2026-01-07T23:59:59.000Z',
                  entries: const <WeeklyLeaderboardEntry>[],
                  myRank: null,
                  myWeeklyPoints: 0,
                );
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(weeklyRankingsNotifierProvider.future),
        throwsA(isA<AppError>()),
      );

      await container
          .read(weeklyRankingsNotifierProvider.notifier)
          .refresh();

      final WeeklyRankingsResult r =
          await container.read(weeklyRankingsNotifierProvider.future);
      expect(r.entries, isEmpty);
      expect(calls, 2);
    });
  });
}
