import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import '../../support/events/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/presentation/screens/events_feed_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_feed_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_filter_chips.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_cupertino_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/shared/widgets/atoms/skeleton_shimmer_box.dart';

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

  testWidgets('EventsFeedSkeleton is one scroll column without nested scroll', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SingleChildScrollView(
          child: EventsFeedSkeleton(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CustomScrollView), findsNothing);
    expect(find.byType(SkeletonShimmerBox), findsWidgets);
  });

  testWidgets('renders discovery search chrome after bootstrap', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForWidgetTest(const EventsFeedScreen()));

    await tester.pump();
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(AppCupertinoSearchField).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(EventsFeedSkeleton), findsNothing);
    expect(find.byType(AppCupertinoSearchField), findsOneWidget);
    expect(find.byType(EventsFilterChips), findsOneWidget);
  });
}
