import 'dart:ui';

import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/feedback_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

EcoEvent _completedEvent() {
  return EcoEvent(
    id: 'e-completed',
    title: 'Park cleanup',
    description: 'Collect litter along the trail.',
    category: EcoEventCategory.riverAndLake,
    siteId: 's1',
    siteName: 'City park',
    siteImageUrl: '',
    siteDistanceKm: 1.2,
    organizerId: 'org-1',
    organizerName: 'Org',
    date: DateTime.utc(2026, 6, 1),
    startTime: const EventTime(hour: 9, minute: 0),
    endTime: const EventTime(hour: 11, minute: 0),
    participantCount: 12,
    status: EcoEventStatus.completed,
    createdAt: DateTime.utc(2026, 1, 1),
    maxParticipants: 30,
    moderationApproved: true,
  );
}

void main() {
  setUpAll(bootstrapWidgetTests);

  testWidgets('overlay mode keeps sheet height stable with keyboard', (
    WidgetTester tester,
  ) async {
    const double keyboardInset = 300;
    const Size surfaceSize = Size(390, 844);

    await tester.binding.setSurfaceSize(surfaceSize);
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    Future<double> sheetHeight({required SheetKeyboardInsetMode mode}) async {
      await tester.pumpWidget(
        wrapForWidgetTest(
          MediaQuery(
            data: const MediaQueryData(size: surfaceSize),
            child: Builder(
              builder: (BuildContext context) {
                final MediaQueryData viewMq = MediaQueryData.fromView(
                  View.of(context),
                );
                Widget sheet = wrapScrollControlledBottomSheet(
                  context: context,
                  keyboardInsetMode: mode,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      viewInsets: viewMq.viewInsets,
                      viewPadding: viewMq.viewPadding,
                    ),
                    child: buildEventFeedbackSheet(
                      context,
                      event: _completedEvent(),
                    ),
                  ),
                );
                if (mode == SheetKeyboardInsetMode.overlay) {
                  sheet = MediaQuery.removeViewInsets(
                    context: context,
                    removeBottom: true,
                    child: sheet,
                  );
                }
                return Align(alignment: Alignment.bottomCenter, child: sheet);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder title = find.text('Post-event feedback');
      expect(title, findsOneWidget);
      final Finder decorated = find.ancestor(
        of: title,
        matching: find.byType(DecoratedBox),
      );
      return tester.getSize(decorated).height;
    }

    final double overlayHeight = await sheetHeight(
      mode: SheetKeyboardInsetMode.overlay,
    );
    final double liftHeight = await sheetHeight(
      mode: SheetKeyboardInsetMode.lift,
    );
    expect(
      overlayHeight,
      greaterThan(liftHeight + 100),
      reason: 'Overlay mode should not shrink the sheet like lift mode',
    );
  });

  testWidgets('feedback sheet bottom stays just above simulated keyboard', (
    WidgetTester tester,
  ) async {
    const double keyboardInset = 300;
    const Size surfaceSize = Size(390, 844);

    await tester.binding.setSurfaceSize(surfaceSize);
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      wrapForWidgetTest(
        MediaQuery(
          data: const MediaQueryData(size: surfaceSize),
          child: Builder(
            builder: (BuildContext context) {
              final MediaQueryData viewMq = MediaQueryData.fromView(
                View.of(context),
              );
              Widget sheet = wrapScrollControlledBottomSheet(
                context: context,
                keyboardInsetMode: SheetKeyboardInsetMode.overlay,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    viewInsets: viewMq.viewInsets,
                    viewPadding: viewMq.viewPadding,
                  ),
                  child: buildEventFeedbackSheet(
                    context,
                    event: _completedEvent(),
                  ),
                ),
              );
              sheet = MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: sheet,
              );
              return Align(alignment: Alignment.bottomCenter, child: sheet);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder saveCta = find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.text('Save impact summary'),
    );
    expect(saveCta, findsOneWidget);

    final Finder notesField = find.byType(TextField);
    expect(notesField, findsOneWidget);

    await tester.dragUntilVisible(
      notesField,
      find.byType(Scrollable).last,
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    await tester.tap(notesField);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    final double keyboardTop = surfaceSize.height - keyboardInset;
    final Rect saveRect = tester.getRect(saveCta);
    final Rect notesRect = tester.getRect(notesField);
    final double sheetBottomGap = keyboardTop - saveRect.bottom;
    final double notesGap = keyboardTop - notesRect.bottom;

    expect(
      sheetBottomGap,
      greaterThan(0),
      reason: 'Sheet footer should sit above the keyboard',
    );
    expect(
      sheetBottomGap,
      lessThan(keyboardInset / 2),
      reason: 'Sheet should not be lifted by a duplicate keyboard inset',
    );
    expect(
      notesGap,
      greaterThan(0),
      reason: 'Focused notes field should stay above the keyboard',
    );
  });
}
