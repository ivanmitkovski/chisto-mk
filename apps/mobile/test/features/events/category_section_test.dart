import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/category_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

EcoEvent _event({EcoEventCategory category = EcoEventCategory.generalCleanup}) {
  return EcoEvent(
    id: 'e1',
    title: 'Cleanup',
    description: 'd',
    category: category,
    siteId: '1',
    siteName: 'Site',
    siteImageUrl: 'assets/test.png',
    siteDistanceKm: 1,
    organizerId: 'org',
    organizerName: 'Org',
    date: DateTime(2025, 6, 1),
    startTime: const EventTime(hour: 10, minute: 0),
    endTime: const EventTime(hour: 11, minute: 0),
    participantCount: 3,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime(2025, 5, 1),
  );
}

void main() {
  testWidgets('shows category label and semantic button', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: CategorySection(event: _event())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('General cleanup'), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(
        find.byType(CategorySection),
      );
      expect(node.label, startsWith('Event category: General cleanup'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tap opens category info bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: CategorySection(event: _event())),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('General cleanup'));
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.textContaining('Pick up litter, sweep debris'), findsOneWidget);
  });

  testWidgets('embedded mode uses grouped metadata row layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: CategorySection(
            event: _event(category: EcoEventCategory.riverAndLake),
            embeddedInGroupedPanel: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('River & lake cleanup'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.info_circle), findsNothing);
  });
}
