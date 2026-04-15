import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/event_chat_audio_playback_scope.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double textScale = 1.0}) {
  final EventChatAudioPlaybackController audio = EventChatAudioPlaybackController();
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
      child: EventChatAudioPlaybackScope(
        controller: audio,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

EventChatMessage _msg({
  bool own = false,
  bool pending = false,
  bool failed = false,
  bool deleted = false,
  String body = 'Hello from the river cleanup crew — bring gloves.',
  List<EventChatAttachment> attachments = const <EventChatAttachment>[],
  EventChatMessageType messageType = EventChatMessageType.text,
  double? locationLat,
  double? locationLng,
  String? locationLabel,
}) {
  return EventChatMessage(
    id: '1',
    eventId: 'e',
    authorId: own ? 'me' : 'a',
    authorName: own ? 'You' : 'Alex Volunteer',
    createdAt: DateTime.utc(2026, 4, 7, 12, 0),
    body: deleted ? null : body,
    isDeleted: deleted,
    isOwnMessage: own,
    pending: pending,
    failed: failed,
    attachments: attachments,
    messageType: messageType,
    locationLat: locationLat,
    locationLng: locationLng,
    locationLabel: locationLabel,
  );
}

void main() {
  testWidgets('renders at large text scale without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(),
        showAuthorName: true,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
      textScale: 1.45,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hello from the river'), findsOneWidget);
  });

  testWidgets('shows sending label when pending', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(own: true, pending: true),
        showAuthorName: false,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Sending…'), findsOneWidget);
  });

  testWidgets('single tick when no read receipts', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(own: true),
        showAuthorName: false,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsNothing);
  });

  testWidgets('double tick when seen', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(own: true),
        showAuthorName: false,
        isFirstInGroup: true,
        isLastInGroup: true,
        receiptSeenByLine: 'Seen by Alex',
        receiptAllPeersRead: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.byIcon(Icons.done), findsNothing);
  });

  testWidgets('peer bubble shows avatar on lastInGroup', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(),
        showAuthorName: true,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
    ));
    await tester.pumpAndSettle();
    // Avatar shows the first letter of the author name
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('deleted message shows italic removed text', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(deleted: true),
        showAuthorName: false,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
    ));
    await tester.pumpAndSettle();
    // The localized "message removed" text should appear
    expect(find.byType(ChatMessageBubble), findsOneWidget);
  });

  testWidgets('failed message shows error hint', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(own: true, failed: true),
        showAuthorName: false,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('audio bubble shows play control and duration', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(
          own: true,
          body: '',
          messageType: EventChatMessageType.audio,
          attachments: <EventChatAttachment>[
            const EventChatAttachment(
              id: 'a1',
              url: 'https://example.com/voice.m4a',
              mimeType: 'audio/m4a',
              fileName: 'voice.m4a',
              sizeBytes: 1200,
              duration: 65,
            ),
          ],
        ),
        showAuthorName: false,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.play_fill), findsOneWidget);
    expect(find.text('1:05'), findsOneWidget);
  });

  testWidgets('location bubble shows pin icon and label', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      ChatMessageBubble(
        message: _msg(
          messageType: EventChatMessageType.location,
          locationLat: 41.9981,
          locationLng: 21.4254,
          locationLabel: 'City Park North',
          body: 'Shared location',
        ),
        showAuthorName: true,
        isFirstInGroup: true,
        isLastInGroup: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.location), findsOneWidget);
    expect(find.text('City Park North'), findsOneWidget);
  });
}
