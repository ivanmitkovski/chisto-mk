import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_list_tile.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routes: <String, WidgetBuilder>{
        AppRoutes.eventsDetail: (_) =>
            const Scaffold(body: Text('event-detail')),
      },
      home: Scaffold(body: child),
    );
  }

  testWidgets('tap with cleanupEventId navigates to event detail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SiteHistoryListTile(
          entry: SiteHistoryEntry(
            id: 'e1',
            kind: SiteHistoryEntryKind.cleanupEventScheduled,
            occurredAt: DateTime(2026, 5, 20),
            cleanupEventId: 'event-42',
          ),
          showDividerBelow: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cleanup event scheduled'));
    await tester.pumpAndSettle();

    expect(find.text('event-detail'), findsOneWidget);
  });

  testWidgets('tap with note toggles show more / show less', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SiteHistoryListTile(
          entry: SiteHistoryEntry(
            id: 'n1',
            kind: SiteHistoryEntryKind.adminNote,
            occurredAt: DateTime(2026, 5, 20),
            note: 'Moderator left a detailed note about this site.',
          ),
          showDividerBelow: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show more'), findsOneWidget);
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('entry without note or event is not a button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SiteHistoryListTile(
          entry: SiteHistoryEntry(
            id: 'e2',
            kind: SiteHistoryEntryKind.siteCreated,
            occurredAt: DateTime(2026, 5, 20),
          ),
          showDividerBelow: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final SemanticsNode node =
        tester.getSemantics(find.byType(SiteHistoryListTile));
    expect(node.hasFlag(SemanticsFlag.isButton), isFalse);
  });
}
