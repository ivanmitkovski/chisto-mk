import 'package:chisto_mobile/features/events/data/check_in_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/in_memory_check_in_repository.dart';
import 'package:chisto_mobile/features/events/data/in_memory_events_store.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show SemanticsAction;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RateLimitedCheckInRepository extends ChangeNotifier implements CheckInRepository {
  @override
  Duration get payloadTtl => const Duration(seconds: 60);

  @override
  bool get supportsOrganizerSimulate => false;

  @override
  Future<void> refreshAttendees(String eventId) async {}

  @override
  Future<String> ensureSession({
    required EcoEvent event,
    bool openIfNeeded = true,
  }) async =>
      '';

  @override
  Future<CheckInQrPayload> issuePayload({required String eventId}) async {
    throw UnimplementedError();
  }

  @override
  Future<CheckInSubmissionResult> submitScan({
    required String rawPayload,
    required String expectedEventId,
    required String attendeeId,
    required String attendeeName,
  }) async {
    return const CheckInSubmissionResult(
      status: CheckInSubmissionStatus.rateLimited,
    );
  }

  @override
  Future<ManualCheckInResult> markAttendeeCheckedIn({
    required String eventId,
    required String attendeeId,
    required String attendeeName,
  }) async =>
      const ManualCheckInResult(recorded: false);

  @override
  Future<bool> removeCheckedInAttendee({
    required String eventId,
    required String attendeeId,
  }) async =>
      false;

  @override
  Future<bool> pauseSession(String eventId) async => false;

  @override
  Future<bool> resumeSession(String eventId) async => false;

  @override
  Future<bool> closeSession(String eventId) async => false;

  @override
  Future<void> rotateSession(String eventId) async {}

  @override
  List<CheckedInAttendee> checkedInAttendees(String eventId) => <CheckedInAttendee>[];

  @override
  int checkedInCount(String eventId) => 0;

  @override
  bool isOpen(String eventId) => false;
}

Widget _appWithReduceMotion(Widget home) {
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
  late InMemoryEventsStore eventsStore;
  late InMemoryCheckInRepository checkInRepository;
  late EcoEvent event;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    eventsStore = InMemoryEventsStore.instance;
    EventsRepositoryRegistry.setTestOverride(eventsStore);
    checkInRepository = InMemoryCheckInRepository.instance;
    checkInRepository.reset();
    eventsStore.resetToSeed();

    event = EcoEvent(
      id: 'evt-qr-widget',
      title: 'QR widget test event',
      description: 'Testing',
      category: EcoEventCategory.generalCleanup,
      siteId: 'site-test',
      siteName: 'Test site',
      siteImageUrl: 'assets/images/references/onboarding_reference.png',
      siteDistanceKm: 1.5,
      organizerId: 'current_user',
      organizerName: 'You',
      date: DateTime.now(),
      startTime: const EventTime(hour: 10, minute: 0),
      endTime: const EventTime(hour: 12, minute: 0),
      participantCount: 3,
      status: EcoEventStatus.inProgress,
      createdAt: DateTime.now(),
      isJoined: true,
    );
    await eventsStore.create(event);
    await checkInRepository.ensureSession(event: event);
    CheckInRepositoryRegistry.setTestOverride(checkInRepository);
  });

  tearDown(() {
    EventsRepositoryRegistry.setTestOverride(null);
    CheckInRepositoryRegistry.setTestOverride(null);
  });

  testWidgets('camera error layer shows permission-blocked guidance in English', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: attendeeQrScannerCameraErrorLayerForTesting(
                context,
                errorCode: MobileScannerErrorCode.permissionDenied,
                onRetryCamera: () {},
                onEnterManually: () {},
              ),
            );
          },
        ),
      ),
    );

    expect(
      find.text(
        'If camera access stays blocked, paste the code manually or enable camera access in Settings.',
      ),
      findsOneWidget,
    );

    final SemanticsNode retryNode = tester.getSemantics(find.text('Retry camera'));
    expect(retryNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(retryNode.label, 'Retry camera');
  });

  testWidgets('simulated valid scan shows checked-in success', (WidgetTester tester) async {
    final CheckInQrPayload payload =
        await checkInRepository.issuePayload(eventId: event.id);

    await tester.pumpWidget(
      _appWithReduceMotion(
        AttendeeQrScannerScreen(
          eventId: event.id,
          scannerTestSlotBuilder: (BuildContext context, void Function(String) simulate) {
            return Center(
              child: TextButton(
                onPressed: () => simulate(payload.encode()),
                child: const Text('simulate_scan'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('simulate_scan'));
    await tester.pumpAndSettle();

    expect(find.text("You're checked in!"), findsOneWidget);
    expect(find.textContaining('QR widget test event'), findsOneWidget);
  });

  testWidgets('wrong-event QR shows localized error', (WidgetTester tester) async {
    final CheckInQrPayload payload =
        await checkInRepository.issuePayload(eventId: event.id);

    await tester.pumpWidget(
      _appWithReduceMotion(
        AttendeeQrScannerScreen(
          eventId: 'other-event-id',
          scannerTestSlotBuilder: (BuildContext context, void Function(String) simulate) {
            return Center(
              child: TextButton(
                onPressed: () => simulate(payload.encode()),
                child: const Text('simulate_scan'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('simulate_scan'));
    await tester.pumpAndSettle();

    expect(find.text('This QR belongs to another event.'), findsOneWidget);
  });

  testWidgets('invalid payload shows invalid format error', (WidgetTester tester) async {
    await tester.pumpWidget(
      _appWithReduceMotion(
        AttendeeQrScannerScreen(
          eventId: event.id,
          scannerTestSlotBuilder: (BuildContext context, void Function(String) simulate) {
            return Center(
              child: TextButton(
                onPressed: () => simulate('not-a-check-in-payload'),
                child: const Text('simulate_scan'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('simulate_scan'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid QR format.'), findsOneWidget);
  });

  testWidgets('rate limited submission shows rate limit copy', (WidgetTester tester) async {
    CheckInRepositoryRegistry.setTestOverride(_RateLimitedCheckInRepository());

    await tester.pumpWidget(
      _appWithReduceMotion(
        AttendeeQrScannerScreen(
          eventId: event.id,
          scannerTestSlotBuilder: (BuildContext context, void Function(String) simulate) {
            return Center(
              child: TextButton(
                onPressed: () => simulate('chisto:evt:v1:x:y:1:1'),
                child: const Text('simulate_scan'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('simulate_scan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Too many attempts. Wait a moment and try again.'),
      findsOneWidget,
    );
  });
}
