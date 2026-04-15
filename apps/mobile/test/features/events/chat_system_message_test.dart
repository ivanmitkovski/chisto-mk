import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_system_message.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatSystemMessage shows join copy', (WidgetTester tester) async {
    final EventChatMessage msg = EventChatMessage(
      id: '1',
      eventId: 'e',
      authorId: 'a',
      authorName: 'Alex',
      createdAt: DateTime.utc(2026, 4, 7, 12, 0),
      body: 'Alex joined the event',
      isDeleted: false,
      isOwnMessage: false,
      messageType: EventChatMessageType.system,
      systemPayload: <String, dynamic>{
        'action': 'user_joined',
        'displayName': 'Alex',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatSystemMessage(message: msg),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Alex'), findsWidgets);
  });
}
