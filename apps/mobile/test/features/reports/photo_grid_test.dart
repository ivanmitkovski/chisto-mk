import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/presentation/widgets/photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(bootstrapWidgetTests);

  testWidgets('compact strip keeps Add tile when one photo is attached', (
    WidgetTester tester,
  ) async {
    int addTaps = 0;

    await tester.pumpWidget(
      wrapForWidgetTest(
        Scaffold(
          body: PhotoGrid(
            photos: <XFile>[XFile('/tmp/photo-a.jpg')],
            compact: true,
            onAddPhoto: () => addTaps++,
            onRemovePhoto: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1 of 5 photos attached'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Add a photo'), findsNothing);

    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(addTaps, 1);
  });

  testWidgets(
    'showExpandedAddCard keeps large add card after photo is attached',
    (WidgetTester tester) async {
      int addTaps = 0;

      await tester.pumpWidget(
        wrapForWidgetTest(
          Scaffold(
            body: PhotoGrid(
              photos: <XFile>[XFile('/tmp/photo-a.jpg')],
              compact: true,
              showExpandedAddCard: true,
              onAddPhoto: () => addTaps++,
              onRemovePhoto: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('1 of 5 photos attached'), findsOneWidget);
      expect(find.text('Add a photo'), findsOneWidget);
      expect(find.text('Camera or library'), findsOneWidget);
      expect(find.text('Add'), findsNothing);

      final Rect addCardRect = tester.getRect(find.text('Add a photo'));
      final Rect thumbnailRect = tester.getRect(find.byIcon(Icons.check_rounded));
      expect(
        addCardRect.top,
        lessThan(thumbnailRect.top),
        reason: 'Large add card should sit above thumbnail attachments',
      );

      await tester.tap(find.text('Add a photo'));
      await tester.pump();
      expect(addTaps, 1);
    },
  );

  testWidgets('hideExpandedAddCard collapses large add card but keeps thumbnails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        Scaffold(
          body: PhotoGrid(
            photos: <XFile>[XFile('/tmp/photo-a.jpg')],
            compact: true,
            showExpandedAddCard: true,
            hideExpandedAddCard: true,
            onAddPhoto: _noop,
            onRemovePhoto: _noopIndex,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(AppMotion.medium);

    expect(find.text('1 of 5 photos attached'), findsOneWidget);
    expect(find.text('Add a photo'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('hideExpandedAddCard restores large add card when cleared', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        Scaffold(
          body: PhotoGrid(
            photos: <XFile>[XFile('/tmp/photo-a.jpg')],
            compact: true,
            showExpandedAddCard: true,
            hideExpandedAddCard: true,
            onAddPhoto: _noop,
            onRemovePhoto: _noopIndex,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(AppMotion.medium);
    expect(find.text('Add a photo'), findsNothing);

    await tester.pumpWidget(
      wrapForWidgetTest(
        Scaffold(
          body: PhotoGrid(
            photos: <XFile>[XFile('/tmp/photo-a.jpg')],
            compact: true,
            showExpandedAddCard: true,
            hideExpandedAddCard: false,
            onAddPhoto: _noop,
            onRemovePhoto: _noopIndex,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(AppMotion.medium);

    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Camera or library'), findsOneWidget);
  });

  testWidgets('compact strip keeps Add tile inside sheet-width layout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapForWidgetTest(
        SizedBox(
          width: 390,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PhotoGrid(
                photos: <XFile>[XFile('/tmp/photo-a.jpg')],
                compact: true,
                onAddPhoto: _noop,
                onRemovePhoto: _noopIndex,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final Finder addLabel = find.text('Add');
    expect(addLabel, findsOneWidget);
    final Rect addRect = tester.getRect(addLabel);
    expect(addRect.width, greaterThan(0));
    expect(addRect.height, greaterThan(0));
    expect(addRect.right, lessThanOrEqualTo(390));
  });
}

void _noop() {}

void _noopIndex(int index) {}
