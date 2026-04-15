import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_input_bar.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatInputBar shows disabled send when empty and no attachments callback',
      (WidgetTester tester) async {
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
          body: ChatInputBar(
            onSend: (_) async {},
          ),
        ),
      ),
    );

    final Finder sendButton = find.byType(FilledButton);
    expect(sendButton, findsOneWidget);
    final FilledButton btn = tester.widget<FilledButton>(sendButton);
    expect(btn.onPressed, isNull);
  });

  testWidgets('ChatInputBar shows mic slot when empty but onSendImages is set',
      (WidgetTester tester) async {
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
          body: ChatInputBar(
            onSend: (_) async {},
            onSendImages: (_) async {},
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byIcon(CupertinoIcons.mic_fill), findsOneWidget);
  });

  testWidgets('ChatInputBar shows send when text is non-empty', (WidgetTester tester) async {
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
          body: ChatInputBar(
            onSend: (_) async {},
            onSendImages: (_) async {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    final Finder sendButton = find.byType(FilledButton);
    expect(sendButton, findsOneWidget);
    final FilledButton btn = tester.widget<FilledButton>(sendButton);
    expect(btn.onPressed, isNotNull);
  });
}
