import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/events_this_week_shelf.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EcoEvent sampleEvent() {
    return EcoEvent(
      id: 'evt-shelf-1',
      title: 'River bank cleanup',
      description: 'D',
      category: EcoEventCategory.generalCleanup,
      siteId: 's1',
      siteName: 'Site',
      siteImageUrl: '',
      siteDistanceKm: 2.5,
      organizerId: 'org-1',
      organizerName: 'Org',
      date: DateTime(2026, 4, 22),
      startTime: const EventTime(hour: 9, minute: 0),
      endTime: const EventTime(hour: 11, minute: 0),
      participantCount: 3,
      status: EcoEventStatus.upcoming,
      createdAt: DateTime(2026, 4, 18),
      moderationApproved: true,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows event row when populated', (WidgetTester tester) async {
    EcoEvent? opened;
    await tester.pumpWidget(
      wrap(
        EventsThisWeekShelf(
          events: <EcoEvent>[sampleEvent()],
          loadFailed: false,
          onRetry: _noop,
          onOpenEvent: (EcoEvent e) => opened = e,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('River bank cleanup'), findsOneWidget);
    await tester.tap(find.text('River bank cleanup'));
    expect(opened?.id, 'evt-shelf-1');
  });

  testWidgets('retry button invokes callback', (WidgetTester tester) async {
    int retries = 0;
    await tester.pumpWidget(
      wrap(
        EventsThisWeekShelf(
          events: <EcoEvent>[],
          loadFailed: true,
          onRetry: () => retries++,
          onOpenEvent: _noopEvent,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('renders nothing when empty and not failed', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const EventsThisWeekShelf(
          events: <EcoEvent>[],
          loadFailed: false,
          onRetry: _noop,
          onOpenEvent: _noopEvent,
        ),
      ),
    );
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(EventsThisWeekShelf), findsOneWidget);
  });
}

void _noop() {}

void _noopEvent(EcoEvent _) {}
