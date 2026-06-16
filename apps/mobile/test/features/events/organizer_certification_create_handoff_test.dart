import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:feature_events/src/domain/models/organizer_certification_submit_result.dart';
import 'package:feature_events/src/domain/models/organizer_quiz_payload.dart';
import 'package:feature_events/src/domain/repositories/organizer_certification_repository.dart';
import 'package:feature_events/src/presentation/navigation/organizer_certification_navigation.dart';
import 'package:feature_events/src/presentation/screens/create_event_sheet.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_quiz_screen.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';
import '../../support/events/in_memory_events_store.dart';
import 'create_event_sheet_test.dart' show createEventSheetTestClock;

class _FakeOrganizerCertificationRepository
    implements OrganizerCertificationRepositoryPort {
  _FakeOrganizerCertificationRepository({
    this.submitResult = const OrganizerCertificationSubmitResult(
      passed: true,
      alreadyCertified: false,
      correctCount: 1,
      totalQuestions: 1,
      pointsAwarded: 50,
      organizerCertifiedAt: null,
    ),
  });

  final OrganizerCertificationSubmitResult submitResult;

  static const OrganizerQuizPayload _payload = OrganizerQuizPayload(
    session: 'test-session',
    rawQuestions: <dynamic>[
      <String, Object>{
        'id': 'q1',
        'text': 'Safety first means?',
        'options': <Map<String, String>>[
          <String, String>{'id': 'a', 'text': 'Plan and communicate'},
          <String, String>{'id': 'b', 'text': 'Skip briefing'},
        ],
      },
    ],
  );

  @override
  Future<OrganizerQuizPayload> fetchQuiz() async => _payload;

  @override
  Future<OrganizerCertificationSubmitResult> submitCertification({
    required String quizSession,
    required List<Map<String, String>> answers,
  }) async {
    return submitResult;
  }
}

Future<void> _advanceToolkitToQuiz(WidgetTester tester) async {
  for (int i = 0; i < 7; i++) {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Take the quiz'));
  await tester.pumpAndSettle();
  expect(find.byType(OrganizerQuizScreen), findsOneWidget);
}

Future<void> _answerQuizAndSubmit(WidgetTester tester) async {
  await tester.tap(find.text('Plan and communicate'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Submit answers'));
  await tester.pumpAndSettle();
  expect(find.text("You're certified!"), findsOneWidget);
}

Future<void> _openCertificationToolkit(
  WidgetTester tester, {
  required VoidCallback onProceedToCreate,
}) async {
  await tester.pumpWidget(
    wrapForWidgetTest(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push<void>(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          name: organizerCertificationToolkitRouteName,
                        ),
                        builder: (_) => OrganizerToolkitScreen(
                          onProceedToCreate: onProceedToCreate,
                        ),
                      ),
                    );
                  },
                  child: const Text('open-toolkit'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-toolkit'));
  await tester.pumpAndSettle();
  expect(find.byType(OrganizerToolkitScreen), findsOneWidget);
}

Finder _toolkitBackButton() {
  return find.descendant(
    of: find.byType(OrganizerToolkitScreen),
    matching: find.byType(AppBackButton),
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    InMemoryEventsStore.instance.resetToSeed();
    setEventsRepositoryTestOverride(InMemoryEventsStore.instance);
    AppBootstrap.instance.authState.setAuthenticated(
      userId: 'u1',
      displayName: 'Tester',
      organizerCertifiedAt: null,
      syncOrganizerCertifiedAt: true,
    );
    setOrganizerCertificationRepositoryTestOverride(
      _FakeOrganizerCertificationRepository(),
    );
  });

  tearDown(() {
    setEventsRepositoryTestOverride(null);
    setOrganizerCertificationRepositoryTestOverride(null);
  });

  testWidgets(
    'quiz pass with missing certifiedAt proceeds to create via onProceedToCreate',
    (WidgetTester tester) async {
      bool wantsCreate = false;
      setOrganizerCertificationRepositoryTestOverride(
        _FakeOrganizerCertificationRepository(
          submitResult: const OrganizerCertificationSubmitResult(
            passed: true,
            alreadyCertified: false,
            correctCount: 1,
            totalQuestions: 1,
            pointsAwarded: 50,
            organizerCertifiedAt: null,
          ),
        ),
      );

      await _openCertificationToolkit(
        tester,
        onProceedToCreate: () => wantsCreate = true,
      );
      await _advanceToolkitToQuiz(tester);
      await _answerQuizAndSubmit(tester);

      expect(AppBootstrap.instance.authState.isOrganizerCertified, isTrue);

      await tester.tap(find.text('Create your first event'));
      await tester.pumpAndSettle();

      expect(wantsCreate, isTrue);
      expect(find.byType(OrganizerToolkitScreen), findsNothing);
      expect(find.byType(OrganizerQuizScreen), findsNothing);
    },
  );

  testWidgets('backing out of toolkit does not open CreateEventSheet', (
    WidgetTester tester,
  ) async {
    bool wantsCreate = false;
    await _openCertificationToolkit(
      tester,
      onProceedToCreate: () => wantsCreate = true,
    );

    await tester.tap(_toolkitBackButton());
    await tester.pumpAndSettle();

    expect(wantsCreate, isFalse);
    expect(find.byType(OrganizerToolkitScreen), findsNothing);
    expect(find.byType(CreateEventSheet), findsNothing);
  });

  testWidgets('CreateEventSheet deep link closes when toolkit is abandoned', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateEventSheet(
                            clock: createEventSheetTestClock,
                          ),
                        ),
                      );
                    },
                    child: const Text('open-create-sheet'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-create-sheet'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(OrganizerToolkitScreen), findsOneWidget);

    await tester.tap(_toolkitBackButton());
    await tester.pumpAndSettle();

    expect(find.byType(OrganizerToolkitScreen), findsNothing);
    expect(find.byType(CreateEventSheet), findsNothing);
  });
}
