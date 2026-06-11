import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_profile/src/domain/models/weekly_rankings_result.dart';
import 'package:feature_profile/src/presentation/providers/profile_providers.dart';
import 'package:feature_profile/src/presentation/providers/weekly_rankings_notifier.dart';
import 'package:feature_profile/src/presentation/screens/weekly_rankings_screen.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_header.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/testing_profile_repository.dart';

WeeklyRankingsResult _rankingsPayload({required int entryCount}) {
  return WeeklyRankingsResult(
    weekStartsAt: '2026-06-01T00:00:00.000Z',
    weekEndsAt: '2026-06-07T23:59:59.999Z',
    myRank: 1,
    myWeeklyPoints: 99,
    entries: List<WeeklyLeaderboardEntry>.generate(
      entryCount,
      (int i) => WeeklyLeaderboardEntry(
        rank: i + 1,
        userId: 'user-$i',
        displayName: 'Supporter $i',
        weeklyPoints: 100 - i,
        isCurrentUser: i == 0,
      ),
    ),
  );
}

Widget _wrapRankingsScreen(WeeklyRankingsResult payload) {
  return ProviderScope(
    overrides: <Override>[
      profileRepositoryProvider.overrideWithValue(
        TestingProfileRepository(
          getMeImpl: () async => throw UnimplementedError(),
          getWeeklyRankingsImpl: ({int limit = 50}) async => payload,
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const WeeklyRankingsScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('pull-to-refresh sits below fixed header chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrapRankingsScreen(_rankingsPayload(entryCount: 3)));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSubScreenHeader), findsOneWidget);
    expect(find.byType(AppRefreshIndicator), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('list bottom padding includes safe scroll inset', (
    WidgetTester tester,
  ) async {
    const double bottomInset = 34;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: bottomInset)),
        child: _wrapRankingsScreen(_rankingsPayload(entryCount: 3)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      ProfileSubScreenPanel.scrollBottomPadding(
        tester.element(find.byType(WeeklyRankingsScreen)),
      ),
      bottomInset + AppSpacing.xl,
    );
  });

  testWidgets('last ranking row scrolls above home indicator inset', (
    WidgetTester tester,
  ) async {
    const double bottomInset = 34;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: bottomInset)),
        child: _wrapRankingsScreen(
          WeeklyRankingsResult(
            weekStartsAt: '2026-06-01T00:00:00.000Z',
            weekEndsAt: '2026-06-07T23:59:59.999Z',
            myRank: null,
            myWeeklyPoints: 0,
            entries: List<WeeklyLeaderboardEntry>.generate(
              20,
              (int i) => WeeklyLeaderboardEntry(
                rank: i + 1,
                userId: 'user-$i',
                displayName: 'Supporter $i',
                weeklyPoints: 100 - i,
                isCurrentUser: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supporter 19'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Supporter 19'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Supporter 19'), findsOneWidget);
  });
}
