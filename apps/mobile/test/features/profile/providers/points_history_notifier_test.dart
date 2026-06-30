import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_profile/src/domain/models/points_history_page.dart';
import 'package:feature_profile/src/presentation/providers/points_history_notifier.dart';
import 'package:feature_profile/src/presentation/providers/profile_providers.dart';
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

      await container
          .read(pointsHistoryNotifierProvider.notifier)
          .loadInitial();
      final PointsHistoryUiState s = container.read(
        pointsHistoryNotifierProvider,
      );
      expect(s.phase, PointsHistoryPhase.ready);
      expect(s.entries.length, 1);
      expect(s.nextCursor, 'c1');
    });

    test('refresh keeps ready phase when list is empty', () async {
      int calls = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          profileRepositoryProvider.overrideWithValue(
            TestingProfileRepository(
              getMeImpl: () async => throw UnimplementedError(),
              getPointsHistoryImpl: ({int limit = 30, String? cursor}) async {
                calls++;
                await Future<void>.delayed(const Duration(milliseconds: 30));
                return const PointsHistoryPage(
                  items: <PointsHistoryEntry>[],
                  milestones: <PointsHistoryMilestone>[],
                );
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(pointsHistoryNotifierProvider, (_, __) {});

      await container
          .read(pointsHistoryNotifierProvider.notifier)
          .loadInitial();
      expect(
        container.read(pointsHistoryNotifierProvider).phase,
        PointsHistoryPhase.ready,
      );

      final Future<void> refreshFuture = container
          .read(pointsHistoryNotifierProvider.notifier)
          .refresh();

      expect(
        container.read(pointsHistoryNotifierProvider).phase,
        PointsHistoryPhase.ready,
      );

      await refreshFuture;
      expect(calls, 2);
      expect(
        container.read(pointsHistoryNotifierProvider).phase,
        PointsHistoryPhase.ready,
      );
    });

    test('refresh keeps ready phase and entries while reloading', () async {
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
                    nextCursor: 'c1',
                  );
                }
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return PointsHistoryPage(
                  items: <PointsHistoryEntry>[
                    PointsHistoryEntry(
                      id: '2',
                      createdAt: DateTime.utc(2026, 1, 2),
                      delta: 3,
                      reasonCode: 'OTHER',
                    ),
                  ],
                  milestones: const <PointsHistoryMilestone>[],
                );
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(pointsHistoryNotifierProvider, (_, __) {});

      await container
          .read(pointsHistoryNotifierProvider.notifier)
          .loadInitial();

      final Future<void> refreshFuture = container
          .read(pointsHistoryNotifierProvider.notifier)
          .refresh();

      final PointsHistoryUiState mid = container.read(
        pointsHistoryNotifierProvider,
      );
      expect(mid.phase, PointsHistoryPhase.ready);
      expect(mid.entries.single.id, '1');

      await refreshFuture;
      final PointsHistoryUiState after = container.read(
        pointsHistoryNotifierProvider,
      );
      expect(after.phase, PointsHistoryPhase.ready);
      expect(after.entries.single.id, '2');
      expect(calls, 2);
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

      container.listen(pointsHistoryNotifierProvider, (_, __) {});

      await container
          .read(pointsHistoryNotifierProvider.notifier)
          .loadInitial();
      await container.read(pointsHistoryNotifierProvider.notifier).loadMore();

      final PointsHistoryUiState s = container.read(
        pointsHistoryNotifierProvider,
      );
      expect(s.entries.length, 1);
      expect(s.loadMoreError, isNotNull);
      expect(calls, 2);
    });
  });
}
