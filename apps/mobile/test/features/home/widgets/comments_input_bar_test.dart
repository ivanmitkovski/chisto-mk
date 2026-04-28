import 'package:chisto_mobile/features/home/presentation/widgets/comments/comments_input_bar.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('send disabled while isCommitting', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'hi');
    final FocusNode focus = FocusNode();
    addTearDown(() {
      controller.dispose();
      focus.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: Scaffold(
          body: CommentsInputBar(
            commentController: controller,
            commentFocusNode: focus,
            editingCommentId: null,
            replyToCommentId: null,
            replyToAuthor: null,
            canPost: true,
            isCommitting: true,
            onTextChanged: (_) {},
            onCommit: ([String? _]) async {},
            onCancelEdit: () {},
            onCancelReply: () {},
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
