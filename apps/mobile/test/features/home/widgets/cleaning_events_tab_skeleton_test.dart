import 'dart:async';

import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/cleaning_events_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../events/recording_events_repository.dart';
import '../support/test_pollution_site.dart';

class _NotReadyEventsRepository extends RecordingEventsRepository {
  _NotReadyEventsRepository();

  final Completer<void> _neverReady = Completer<void>();

  @override
  bool get isReady => false;

  @override
  Future<void> get ready => _neverReady.future;

  @override
  List<EcoEvent> get events => const <EcoEvent>[];
}

void main() {
  setUp(() {
    setEventsRepositoryTestOverride(_NotReadyEventsRepository());
  });

  tearDown(() {
    setEventsRepositoryTestOverride(null);
  });

  testWidgets('renders high-fidelity loading skeleton with stable CTA area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: CleaningEventsTab(
            site: buildTestPollutionSite(id: 'site-1'),
            onCreateEvent: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.bySemanticsLabel('Loading eco actions.'), findsOneWidget);
    expect(
      find.byKey(const Key('cleaning-events-skeleton-card-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('cleaning-events-skeleton-card-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('cleaning-events-skeleton-card-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('cleaning-events-skeleton-cta')),
      findsOneWidget,
    );
    expect(find.text('Create eco action'), findsNothing);
  });
}
