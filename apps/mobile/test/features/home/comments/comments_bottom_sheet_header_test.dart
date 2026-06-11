import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_bottom_sheet_header.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_sheet_drag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpHeaderInSheet(
  WidgetTester tester, {
  required DraggableScrollableController sheetController,
  String? siteTitle,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en')],
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            DraggableScrollableSheet(
              controller: sheetController,
              initialChildSize: kCommentsSheetInitialSize,
              minChildSize: kCommentsSheetMinSize,
              maxChildSize: kCommentsSheetMaxSize,
              snap: true,
              snapSizes: kCommentsSheetSnapSizes,
              builder: (BuildContext context, ScrollController scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: CommentsBottomSheetHeader(
                    siteTitle: siteTitle,
                    sheetController: sheetController,
                    sizeConfig: CommentsSheetSizeConfig.standard,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drag starting on title resizes the sheet', (WidgetTester tester) async {
    final DraggableScrollableController sheetController =
        DraggableScrollableController();
    addTearDown(sheetController.dispose);

    await _pumpHeaderInSheet(tester, sheetController: sheetController);

    expect(sheetController.isAttached, isTrue);
    final double initialSize = sheetController.size;

    await tester.drag(find.text('Comments'), const Offset(0, 120));
    await tester.pump();

    expect(sheetController.size, lessThan(initialSize));
  });

  testWidgets('drag starting on site title resizes the sheet', (WidgetTester tester) async {
    final DraggableScrollableController sheetController =
        DraggableScrollableController();
    addTearDown(sheetController.dispose);

    await _pumpHeaderInSheet(
      tester,
      sheetController: sheetController,
      siteTitle: 'River bank cleanup',
    );

    expect(sheetController.isAttached, isTrue);
    final double initialSize = sheetController.size;

    await tester.drag(find.text('River bank cleanup'), const Offset(0, 120));
    await tester.pump();

    expect(sheetController.size, lessThan(initialSize));
  });

  testWidgets('header is inert without sheet controller', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en')],
        home: const Scaffold(
          body: CommentsBottomSheetHeader(siteTitle: 'Test site'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(CommentsBottomSheetHeader),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
  });
}
