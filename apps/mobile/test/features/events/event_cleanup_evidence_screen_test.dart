import 'dart:io';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_cleanup_evidence_screen.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show SemanticsAction;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Widget _reduceMotionApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      );
    },
    home: home,
  );
}

void main() {
  late InMemoryEventsStore store;
  late EcoEvent event;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryEventsStore.instance;
    EventsRepositoryRegistry.setTestOverride(store);
    store.resetToSeed();
    // Match app order: [EventCleanupEvidenceScreen] calls [loadInitialIfNeeded] in
    // [initState]. If that runs before [_didStartLoad] is true, it replaces [_events]
    // with seed only and drops any event created only in this [setUp].
    store.loadInitialIfNeeded();
    tempDir = await Directory.systemTemp.createTemp('evidence_widget_test');
    event = EcoEvent(
      id: 'evt-evidence-widget',
      title: 'Evidence test event',
      description: 'Desc',
      category: EcoEventCategory.generalCleanup,
      siteId: '1',
      siteName: 'Site',
      siteImageUrl: 'assets/images/references/onboarding_reference.png',
      siteDistanceKm: 2,
      organizerId: 'current_user',
      organizerName: 'You',
      date: DateTime.now(),
      startTime: const EventTime(hour: 9, minute: 0),
      endTime: const EventTime(hour: 11, minute: 0),
      participantCount: 2,
      status: EcoEventStatus.inProgress,
      createdAt: DateTime.now(),
      isJoined: true,
      afterImagePaths: const <String>[],
    );
    await store.create(event);
  });

  tearDown(() async {
    EventsRepositoryRegistry.setTestOverride(null);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('upload semantic is present on empty after tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      _reduceMotionApp(
        EventCleanupEvidenceScreen(eventId: event.id),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Add photos of the cleaned site'), findsOneWidget);
    final SemanticsNode node =
        tester.getSemantics(find.text('Add photos of the cleaned site'));
    expect(node.label, contains('Upload after photos'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('pick (test hook), save, pop and success snack', (WidgetTester tester) async {
    const String assetPhoto =
        'assets/images/references/onboarding_reference.png';

    await tester.pumpWidget(
      _reduceMotionApp(
        EventCleanupEvidenceScreen(
          eventId: event.id,
          testPickAfterImagePathsOverride: () async => <String>[assetPhoto],
        ),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Add photos of the cleaned site'));
    await _pumpUi(tester);

    expect(find.text('Save'), findsOneWidget);
    final Finder saveKey = find.byKey(const ValueKey<String>('cleanupEvidenceSave'));
    await tester.ensureVisible(saveKey);
    await tester.tap(saveKey);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('After photos saved.'), findsOneWidget);
  });

  testWidgets('save failure then retry succeeds', (WidgetTester tester) async {
    const String assetPhoto =
        'assets/images/references/onboarding_reference.png';
    int attempts = 0;

    await tester.pumpWidget(
      _reduceMotionApp(
        EventCleanupEvidenceScreen(
          eventId: event.id,
          testPickAfterImagePathsOverride: () async => <String>[assetPhoto],
          testSetAfterImagesOverride:
              ({required String eventId, required List<String> imagePaths}) async {
            attempts++;
            if (attempts == 1) {
              throw AppError.server(message: 'Upload failed');
            }
            return store.setAfterImages(
              eventId: eventId,
              imagePaths: imagePaths,
            );
          },
        ),
      ),
    );
    await _pumpUi(tester);
    await tester.tap(find.text('Add photos of the cleaned site'));
    await _pumpUi(tester);

    final Finder saveKey = find.byKey(const ValueKey<String>('cleanupEvidenceSave'));
    await tester.ensureVisible(saveKey);
    await tester.tapAt(tester.getCenter(saveKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Upload failed'), findsOneWidget);

    // iOS-style [AppSnack] uses a short-lived overlay; wait for it to dismiss
    // so the second Save tap is not obscured.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(saveKey, findsOneWidget);
    final PrimaryButton saveBtn = tester.widget<PrimaryButton>(saveKey);
    expect(saveBtn.enabled, isTrue);
    expect(saveBtn.onPressed, isNotNull);
    await tester.ensureVisible(saveKey);
    await tester.tapAt(tester.getCenter(saveKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(attempts, 2);
    expect(find.text('After photos saved.'), findsOneWidget);
  });

  testWidgets('save button exposes save semantics with hint', (WidgetTester tester) async {
    const String assetPhoto =
        'assets/images/references/onboarding_reference.png';

    await tester.pumpWidget(
      _reduceMotionApp(
        EventCleanupEvidenceScreen(
          eventId: event.id,
          testPickAfterImagePathsOverride: () async => <String>[assetPhoto],
        ),
      ),
    );
    await _pumpUi(tester);
    await tester.tap(find.text('Add photos of the cleaned site'));
    await _pumpUi(tester);

    final Element saveTextEl = tester.element(find.text('Save'));
    Semantics? semanticsWithHint;
    saveTextEl.visitAncestorElements((Element ancestor) {
      final Widget w = ancestor.widget;
      if (w is Semantics) {
        final String? h = w.properties.hint;
        if (h != null && h.isNotEmpty) {
          semanticsWithHint = w;
          return false;
        }
      }
      return true;
    });
    expect(semanticsWithHint, isNotNull);
    expect(
      semanticsWithHint!.properties.hint,
      contains('After photos document your results'),
    );
  });
}
