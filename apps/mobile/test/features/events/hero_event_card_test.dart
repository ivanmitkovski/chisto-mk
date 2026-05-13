import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed/hero_event_card.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EcoEvent sampleHeroEvent() {
    final DateTime date = DateTime.now().add(const Duration(days: 2));
    return EcoEvent(
      id: 'evt-hero-1',
      title: 'тест',
      description: 'D',
      category: EcoEventCategory.generalCleanup,
      siteId: 's1',
      siteName: 'Bulevar Partizanski odredi 4, Skopje',
      siteImageUrl: '',
      siteDistanceKm: 1.2,
      organizerId: 'org-1',
      organizerName: 'Org',
      date: date,
      startTime: const EventTime(hour: 20, minute: 25),
      endTime: const EventTime(hour: 22, minute: 25),
      participantCount: 0,
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
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders title, up next badge, and meets hero media height', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          child: HeroEventCard(
            event: sampleHeroEvent(),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('тест'), findsOneWidget);
    expect(find.text('Up next'), findsOneWidget);
    expect(find.textContaining('Starts in'), findsOneWidget);

    final Finder sized = find.byWidgetPredicate(
      (Widget w) => w is SizedBox && w.height == AppSpacing.eventsHeroCardMediaHeight,
    );
    expect(sized, findsWidgets);
  });

  testWidgets('Semantics bundles title, countdown, and site name', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          child: HeroEventCard(
            event: sampleHeroEvent(),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    final Iterable<Semantics> semanticsNodes = tester.widgetList<Semantics>(
      find.descendant(of: find.byType(HeroEventCard), matching: find.byType(Semantics)),
    );
    final bool hasBundledLabel = semanticsNodes.any((Semantics s) {
      final String? label = s.properties.label;
      return label != null &&
          label.contains('тест') &&
          label.contains('Starts in') &&
          label.contains('Bulevar Partizanski');
    });
    expect(hasBundledLabel, isTrue);

    final bool hasHint =
        semanticsNodes.any((Semantics s) => (s.properties.hint ?? '').isNotEmpty);
    expect(hasHint, isTrue);
  });
}
