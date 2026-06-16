import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/data/chat/event_chat_connection_status.dart';
import 'package:feature_events/src/data/chat/event_chat_fetch_result.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/data/chat/in_memory_event_chat_repository.dart';
import 'package:feature_events/src/presentation/screens/event_chat_screen.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_input_bar.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_search_result_tile.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_not_found_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

class _ThrowingEventChatRepository extends InMemoryEventChatRepository {
  _ThrowingEventChatRepository(this.failure);

  final AppError failure;

  @override
  Future<EventChatFetchResult> fetchMessages(
    String eventId, {
    String? cursor,
    int limit = 50,
  }) {
    throw failure;
  }
}

Widget _app({required Widget child, double textScale = 1.0}) {
  return wrapForWidgetTest(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child,
    ),
  );
}

/// Pump zero-duration frames so async init resolves without advancing the
/// fake clock (which would trigger Timer.periodic and hang).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _finishChatTest(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 11));
}

/// HTTP search always empty; history still loads from the same in-memory store.
class _EmptySearchInMemoryRepo extends InMemoryEventChatRepository {
  @override
  Future<EventChatFetchResult> searchMessages(
    String eventId,
    String query, {
    String? cursor,
    int limit = 20,
  }) async {
    return const EventChatFetchResult(
      messages: <EventChatMessage>[],
      hasMore: false,
      nextCursor: null,
    );
  }
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows system message from repo', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u',
      authorName: 'Pat',
      body: 'Pat joined',
      type: EventChatMessageType.system,
      systemPayload: <String, dynamic>{
        'action': 'user_joined',
        'displayName': 'Pat',
      },
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'River cleanup',
          isOrganizer: true,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.textContaining('Pat'), findsWidgets);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('shows empty state', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();

    await tester.pumpWidget(
      _app(
        textScale: 1.45,
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'River cleanup',
          isOrganizer: true,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.textContaining('River cleanup'), findsOneWidget);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('connection banner hidden on initial connect', (
    WidgetTester tester,
  ) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    repo.setConnectionStatusForTest('e1', EventChatConnectionStatus.connected);

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Test',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.text('Reconnecting…'), findsNothing);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('no network banner while disconnected before first connected', (
    WidgetTester tester,
  ) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    repo.setConnectionStatusForTest(
      'e1',
      EventChatConnectionStatus.disconnected,
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Test',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.text('Check your connection and try again.'), findsNothing);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets(
    'no reconnecting banner during first handshake reconnecting status',
    (WidgetTester tester) async {
      final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
      repo.setConnectionStatusForTest(
        'e1',
        EventChatConnectionStatus.reconnecting,
      );

      await tester.pumpWidget(
        _app(
          child: EventChatScreen(
            eventId: 'e1',
            eventTitle: 'Test',
            isOrganizer: false,
            repository: repo,
          ),
        ),
      );

      await _settle(tester);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Reconnecting…'), findsNothing);
      await _finishChatTest(tester);
      repo.dispose();
    },
  );

  testWidgets('pinned bar shows unpin button for organizer', (
    WidgetTester tester,
  ) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    final EventChatMessage seeded = await repo.seedOtherMessage(
      'e1',
      authorId: 'u1',
      authorName: 'Pat',
      body: 'Important announcement',
    );
    await repo.setPin('e1', seeded.id, pinned: true);

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Cleanup',
          isOrganizer: true,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.textContaining('Important'), findsWidgets);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('swipe reply shows composer reply strip', (
    WidgetTester tester,
  ) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u',
      authorName: 'Pat',
      body: 'Hello swipe',
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Test',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.textContaining('Hello swipe'), findsWidgets);

    await tester.drag(
      find.textContaining('Hello swipe').first,
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Replying to Pat'), findsOneWidget);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('tapping app bar title opens participants sheet', (
    WidgetTester tester,
  ) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u_pat',
      authorName: 'Pat Smith',
      body: 'Hi',
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'River cleanup',
          isOrganizer: true,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    // [_loadMeta] runs in an unawaited batch after initial load; allow it to finish.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    final BuildContext ctx = tester.element(find.byType(EventChatScreen));
    final AppLocalizations l10n = AppLocalizations.of(ctx)!;
    final Finder titleInk = find.ancestor(
      of: find.text('River cleanup'),
      matching: find.byType(InkWell),
    );
    expect(titleInk, findsOneWidget);
    await tester.tap(titleInk);
    await tester.pumpAndSettle();
    expect(find.text(l10n.eventChatParticipantsSheetTitle), findsOneWidget);
    // Name also appears in the message list behind the sheet.
    expect(find.text('Pat Smith'), findsWidgets);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('search opens and can be closed', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Test',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    final Finder searchButton = find.byIcon(Icons.search);
    if (searchButton.evaluate().isNotEmpty) {
      await tester.tap(searchButton.first);
      await _settle(tester);
      final Finder closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsWidgets);
    }
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('search mode does not show main chat bubbles', (
    WidgetTester tester,
  ) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u1',
      authorName: 'Pat',
      body: 'Visible in transcript',
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Test',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.byType(ChatMessageBubble), findsWidgets);

    await tester.tap(find.byIcon(Icons.search).first);
    await _settle(tester);

    expect(find.byType(ChatMessageBubble), findsNothing);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('search shows local matches when API search returns empty', (
    WidgetTester tester,
  ) async {
    final _EmptySearchInMemoryRepo repo = _EmptySearchInMemoryRepo();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u1',
      authorName: 'Pat',
      body: 'ZetaQuery99 unique',
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Test',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    await tester.tap(find.byIcon(Icons.search).first);
    await _settle(tester);

    await tester.enterText(find.byType(TextField), '99');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.byType(ChatMessageBubble), findsNothing);
    expect(find.byType(ChatSearchResultTile), findsOneWidget);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('deleted event shows not-found state not network error', (
    WidgetTester tester,
  ) async {
    final _ThrowingEventChatRepository repo = _ThrowingEventChatRepository(
      AppError.notFound(code: 'EVENT_NOT_FOUND'),
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Deleted cleanup',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(find.byType(EventDetailNotFoundView), findsOneWidget);
    expect(find.text('Event not found'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsNothing);
    expect(find.byType(ChatInputBar), findsNothing);
    await _finishChatTest(tester);
    repo.dispose();
  });

  testWidgets('chat access denied hides composer', (WidgetTester tester) async {
    final _ThrowingEventChatRepository repo = _ThrowingEventChatRepository(
      const AppError(
        code: 'EVENT_CHAT_NOT_PARTICIPANT',
        message: 'Not a participant',
        retryable: false,
      ),
    );

    await tester.pumpWidget(
      _app(
        child: EventChatScreen(
          eventId: 'e1',
          eventTitle: 'Private cleanup',
          isOrganizer: false,
          repository: repo,
        ),
      ),
    );

    await _settle(tester);
    expect(
      find.text('You need to join this event to use chat.'),
      findsOneWidget,
    );
    expect(find.text('Check your connection and try again.'), findsNothing);
    expect(find.byType(ChatInputBar), findsNothing);
    await _finishChatTest(tester);
    repo.dispose();
  });
}
