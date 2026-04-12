import 'package:chisto_mobile/features/events/data/chat/event_chat_message.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_image_gallery_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatImageGalleryScreen shows page indicator', (WidgetTester tester) async {
    const List<EventChatAttachment> attachments = <EventChatAttachment>[
      EventChatAttachment(
        id: '1',
        url: 'https://example.com/a.jpg',
        mimeType: 'image/jpeg',
        fileName: 'a.jpg',
        sizeBytes: 1,
      ),
      EventChatAttachment(
        id: '2',
        url: 'https://example.com/b.jpg',
        mimeType: 'image/jpeg',
        fileName: 'b.jpg',
        sizeBytes: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ChatImageGalleryScreen(
          attachments: attachments,
          initialIndex: 0,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('1 of 2'), findsOneWidget);
  });
}
