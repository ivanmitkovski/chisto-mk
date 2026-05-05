import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/points_history_notifier.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/testing_profile_repository.dart';

void main() {
  group('PointsHistoryNotifier', () {
    test('loadInitial fills entries and milestones', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            TestingProfileRepository(
              getMeImpl: () async => throw UnimplementedError(),
              getPointsHistoryImpl: ({int limit = 30, String? cursor}) async {
                expect(cursor, isNull);
                return PointsHistoryPage(
                  items: <PointsHistoryEntry>[
                    PointsHistoryEntry(
                      id: '1',
                      createdAt: DateTime.utc(2026, 1, 2, 12),
                      delta: 5,
                      reasonCode: 'REPORT_APPROVED',
                    ),
                  ],
                  milestones: const <PointsHistoryMilestone>[],
                  nextCursor: 'c1',
                );
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pointsHistoryNotifierProvider.notifier).loadInitial();
      final PointsHistoryUiState s = container.read(pointsHistoryNotifierProvider);
      expect(s.phase, PointsHistoryPhase.ready);
      expect(s.entries.length, 1);
      expect(s.nextCursor, 'c1');
    });

    test('loadMore appends and surfaces loadMoreError on failure', () async {
      int calls = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            TestingProfileRepository(
              getMeImpl: () async => throw UnimplementedError(),
              getPointsHistoryImpl: ({int limit = 30, String? cursor}) async {
                calls++;
                if (calls == 1) {
                  return PointsHistoryPage(
                    items: <PointsHistoryEntry>[
                      PointsHistoryEntry(
                        id: '1',
                        createdAt: DateTime.utc(2026, 1, 1),
                        delta: 1,
                        reasonCode: 'OTHER',
                      ),
                    ],
                    milestones: const <PointsHistoryMilestone>[],
                    nextCursor: 'next',
                  );
                }
                throw AppError.unknown();
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pointsHistoryNotifierProvider.notifier).loadInitial();
      await container.read(pointsHistoryNotifierProvider.notifier).loadMore();

      final PointsHistoryUiState s = container.read(pointsHistoryNotifierProvider);
      expect(s.entries.length, 1);
      expect(s.loadMoreError, isNotNull);
      expect(calls, 2);
    });
  });
}
