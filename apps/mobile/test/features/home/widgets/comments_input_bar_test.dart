import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/utils/comment_input_validator.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_input_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapInputBar({
  required TextEditingController controller,
  required FocusNode focus,
  required bool canPost,
  Future<void> Function([String? raw])? onCommit,
}) {
  return MaterialApp(
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
        canPost: canPost,
        isCommitting: false,
        onTextChanged: (_) {},
        onCommit: onCommit ?? ([String? _]) async {},
        onCancelEdit: () {},
        onCancelReply: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('send disabled while isCommitting', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'hi');
    final FocusNode focus = FocusNode();
    addTearDown(() {
      controller.dispose();
      focus.dispose();
    });
    await tester.pumpWidget(
      _wrapInputBar(controller: controller, focus: focus, canPost: true),
    );
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

  testWidgets('input stops at maxBodyLength characters', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode focus = FocusNode();
    addTearDown(() {
      controller.dispose();
      focus.dispose();
    });

    await tester.pumpWidget(
      _wrapInputBar(controller: controller, focus: focus, canPost: true),
    );

    await tester.enterText(
      find.byType(TextField),
      'a' * (CommentInputValidator.maxBodyLength + 50),
    );
    await tester.pump();

    expect(controller.text.length, CommentInputValidator.maxBodyLength);
  });

  testWidgets('send does not commit when canPost is false', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(text: 'hi');
    final FocusNode focus = FocusNode();
    var commitCount = 0;
    addTearDown(() {
      controller.dispose();
      focus.dispose();
    });

    await tester.pumpWidget(
      _wrapInputBar(
        controller: controller,
        focus: focus,
        canPost: false,
        onCommit: ([String? _]) async {
          commitCount++;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(commitCount, 0);
  });

  testWidgets('shows counter when within 100 chars of limit', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: 'a' * 420,
    );
    final FocusNode focus = FocusNode();
    addTearDown(() {
      controller.dispose();
      focus.dispose();
    });

    await tester.pumpWidget(
      _wrapInputBar(controller: controller, focus: focus, canPost: true),
    );

    expect(find.text('80 characters left'), findsOneWidget);
  });

  testWidgets('overlay model composer fits constrained sheet height', (
    WidgetTester tester,
  ) async {
    const double keyboardInset = 336;
    final TextEditingController controller = TextEditingController();
    final FocusNode focus = FocusNode();
    addTearDown(() {
      controller.dispose();
      focus.dispose();
      tester.view.resetViewInsets();
    });

    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: Scaffold(
                body: SizedBox(
                  height: 489.4,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 80, child: Text('Header')),
                      const Expanded(child: SizedBox.shrink()),
                      CommentsInputBar(
                        commentController: controller,
                        commentFocusNode: focus,
                        keyboardOverlaysSheet: true,
                        editingCommentId: null,
                        replyToCommentId: null,
                        replyToAuthor: null,
                        canPost: false,
                        onTextChanged: (_) {},
                        onCommit: ([String? _]) async {},
                        onCancelEdit: () {},
                        onCancelReply: () {},
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      appSheetOverlayKeyboardInset(tester.element(find.byType(Scaffold))),
      keyboardInset,
    );
  });
}
