import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/presentation/screens/events_feed_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_filter_chips.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_cupertino_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() async {
    InMemoryEventsStore.instance.resetToSeed();
    EventsRepositoryRegistry.setTestOverride(InMemoryEventsStore.instance);
    InMemoryEventsStore.instance.loadInitialIfNeeded();
    await InMemoryEventsStore.instance.ready;
  });

  tearDown(() {
    EventsRepositoryRegistry.setTestOverride(null);
  });

  testWidgets('renders discovery search chrome after bootstrap', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const EventsFeedScreen(),
      ),
    );

    await tester.pump();
    final bool sawSkeleton = find.byType(EventsFeedSkeleton).evaluate().isNotEmpty;
    if (sawSkeleton) {
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(AppCupertinoSearchField), findsOneWidget);
    expect(find.byType(EventsFilterChips), findsOneWidget);
  });
}
