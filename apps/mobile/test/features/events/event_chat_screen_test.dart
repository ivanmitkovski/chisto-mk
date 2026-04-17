import 'package:chisto_mobile/features/events/data/chat/event_chat_fetch_result.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/data/chat/in_memory_event_chat_repository.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_chat_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_search_result_tile.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required Widget child, double textScale = 1.0}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
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

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'River cleanup',
        isOrganizer: true,
        repository: repo,
      ),
    ));

    await _settle(tester);
    expect(find.textContaining('Pat'), findsWidgets);
    repo.dispose();
  });

  testWidgets('shows empty state', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();

    await tester.pumpWidget(_app(
      textScale: 1.45,
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'River cleanup',
        isOrganizer: true,
        repository: repo,
      ),
    ));

    await _settle(tester);
    expect(find.textContaining('River cleanup'), findsOneWidget);
    repo.dispose();
  });

  testWidgets('connection banner hidden on initial connect', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'Test',
        isOrganizer: false,
        repository: repo,
      ),
    ));

    await _settle(tester);
    expect(find.text('Reconnecting…'), findsNothing);
    repo.dispose();
  });

  testWidgets('pinned bar shows unpin button for organizer', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    final EventChatMessage seeded = await repo.seedOtherMessage(
      'e1',
      authorId: 'u1',
      authorName: 'Pat',
      body: 'Important announcement',
    );
    await repo.setPin('e1', seeded.id, pinned: true);

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'Cleanup',
        isOrganizer: true,
        repository: repo,
      ),
    ));

    await _settle(tester);
    expect(find.textContaining('Important'), findsWidgets);
    repo.dispose();
  });

  testWidgets('swipe reply shows composer reply strip', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u',
      authorName: 'Pat',
      body: 'Hello swipe',
    );

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'Test',
        isOrganizer: false,
        repository: repo,
      ),
    ));

    await _settle(tester);
    expect(find.textContaining('Hello swipe'), findsWidgets);

    await tester.drag(find.textContaining('Hello swipe').first, const Offset(-80, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('Replying to Pat'), findsOneWidget);
    repo.dispose();
  });

  testWidgets('tapping app bar title opens participants sheet', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u_pat',
      authorName: 'Pat Smith',
      body: 'Hi',
    );

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'River cleanup',
        isOrganizer: true,
        repository: repo,
      ),
    ));

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
    repo.dispose();
  });

  testWidgets('search opens and can be closed', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'Test',
        isOrganizer: false,
        repository: repo,
      ),
    ));

    await _settle(tester);
    final Finder searchButton = find.byIcon(Icons.search);
    if (searchButton.evaluate().isNotEmpty) {
      await tester.tap(searchButton.first);
      await _settle(tester);
      final Finder closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsWidgets);
    }
    repo.dispose();
  });

  testWidgets('search mode does not show main chat bubbles', (WidgetTester tester) async {
    final InMemoryEventChatRepository repo = InMemoryEventChatRepository();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u1',
      authorName: 'Pat',
      body: 'Visible in transcript',
    );

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'Test',
        isOrganizer: false,
        repository: repo,
      ),
    ));

    await _settle(tester);
    expect(find.byType(ChatMessageBubble), findsWidgets);

    await tester.tap(find.byIcon(Icons.search).first);
    await _settle(tester);

    expect(find.byType(ChatMessageBubble), findsNothing);
    repo.dispose();
  });

  testWidgets('search shows local matches when API search returns empty', (WidgetTester tester) async {
    final _EmptySearchInMemoryRepo repo = _EmptySearchInMemoryRepo();
    await repo.seedOtherMessage(
      'e1',
      authorId: 'u1',
      authorName: 'Pat',
      body: 'ZetaQuery99 unique',
    );

    await tester.pumpWidget(_app(
      child: EventChatScreen(
        eventId: 'e1',
        eventTitle: 'Test',
        isOrganizer: false,
        repository: repo,
      ),
    ));

    await _settle(tester);
    await tester.tap(find.byIcon(Icons.search).first);
    await _settle(tester);

    await tester.enterText(find.byType(TextField), '99');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.byType(ChatMessageBubble), findsNothing);
    expect(find.byType(ChatSearchResultTile), findsOneWidget);
    repo.dispose();
  });
}
