import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_input_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _sendInkWell(WidgetTester tester) {
  return find.ancestor(
    of: find.byIcon(CupertinoIcons.arrow_up).first,
    matching: find.byType(InkWell),
  );
}

void main() {
  testWidgets(
    'ChatInputBar shows disabled send when empty and no attachments callback',
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
          home: Scaffold(body: ChatInputBar(onSend: (_) async {})),
        ),
      );

      expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);
      final InkWell send = tester.widget<InkWell>(_sendInkWell(tester));
      expect(send.onTap, isNull);
    },
  );

  testWidgets(
    'ChatInputBar shows mic slot when empty but onSendImages is set',
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

      expect(find.byIcon(CupertinoIcons.arrow_up), findsNothing);
      expect(find.byIcon(CupertinoIcons.mic_fill), findsOneWidget);
    },
  );

  testWidgets('ChatInputBar shows send when text is non-empty', (
    WidgetTester tester,
  ) async {
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
          body: ChatInputBar(onSend: (_) async {}, onSendImages: (_) async {}),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);
    final InkWell send = tester.widget<InkWell>(_sendInkWell(tester));
    expect(send.onTap, isNotNull);
  });
}
