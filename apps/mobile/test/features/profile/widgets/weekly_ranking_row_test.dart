import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_profile/src/domain/models/weekly_rankings_result.dart';
import 'package:feature_profile/src/presentation/widgets/weekly_ranking_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Future<void> pumpRow(
    WidgetTester tester,
    WeeklyLeaderboardEntry entry,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: WeeklyRankingRow(entry: entry)),
      ),
    );
    await tester.pump();
  }

  testWidgets('top three ranks show trophy icon instead of rank number', (
    WidgetTester tester,
  ) async {
    await pumpRow(
      tester,
      const WeeklyLeaderboardEntry(
        rank: 1,
        userId: 'u1',
        displayName: 'Alice',
        weeklyPoints: 42,
        isCurrentUser: false,
      ),
    );

    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('ranks below top three show numeric rank', (
    WidgetTester tester,
  ) async {
    await pumpRow(
      tester,
      const WeeklyLeaderboardEntry(
        rank: 8,
        userId: 'u2',
        displayName: 'Bob',
        weeklyPoints: 10,
        isCurrentUser: false,
      ),
    );

    expect(find.text('8'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
  });

  testWidgets('empty display name uses question mark initial', (
    WidgetTester tester,
  ) async {
    await pumpRow(
      tester,
      const WeeklyLeaderboardEntry(
        rank: 4,
        userId: 'u3',
        displayName: '',
        weeklyPoints: 0,
        isCurrentUser: false,
      ),
    );

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('exposes weekly rank row semantics', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: WeeklyRankingRow(
              entry: const WeeklyLeaderboardEntry(
                rank: 2,
                userId: 'u4',
                displayName: 'Carol',
                weeklyPoints: 15,
                isCurrentUser: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final SemanticsNode node = tester.getSemantics(
        find.byType(WeeklyRankingRow),
      );
      expect(node.label, startsWith('Rank 2, Carol, 15 points'));
    } finally {
      semantics.dispose();
    }
  });
}
