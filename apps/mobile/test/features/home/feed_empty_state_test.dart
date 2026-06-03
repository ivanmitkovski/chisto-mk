import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/widgets/feed_empty_state.dart';
import 'package:feature_home/src/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('FeedEmptyState shows pull-to-refresh for all filter', (
    WidgetTester tester,
  ) async {
    var refreshed = false;
    await tester.pumpWidget(
      wrap(
        FeedEmptyState(
          activeFilter: FeedFilter.all,
          locationAvailable: true,
          onShowAllSites: () {},
          onRefresh: () => refreshed = true,
        ),
      ),
    );

    expect(find.text('Pull to refresh'), findsOneWidget);
    await tester.tap(find.text('Pull to refresh'));
    await tester.pump();
    expect(refreshed, isTrue);
  });

  testWidgets('FeedEmptyState uses AnimatedSwitcher for icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        FeedEmptyState(
          activeFilter: FeedFilter.urgent,
          locationAvailable: true,
          onShowAllSites: () {},
          onRefresh: () {},
        ),
      ),
    );

    expect(find.byType(AnimatedSwitcher), findsOneWidget);
  });
}
