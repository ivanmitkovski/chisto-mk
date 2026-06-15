import 'dart:async';
import 'dart:ui';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:design_system/design_system.dart';
import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/widgets/submit_resolution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widget_test_bootstrap.dart';

const Size _surfaceSize = Size(390, 844);
const double _homeIndicatorInset = 34;
const double _keyboardInset = 300;

const String _helpText =
    'An admin will review your photos before the site is marked resolved.';

const String _longSiteTitle = 'Overflowing Trash Containers on the Sidewalk';

const String _longSiteSubtitle =
    'Add photos showing Overflowing Trash Containers on the Sidewalk after cleanup';

void _configureTestView(
  WidgetTester tester, {
  double keyboardInset = 0,
  double topInset = 0,
}) {
  tester.view.physicalSize = _surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewPadding = FakeViewPadding(
    top: topInset,
    bottom: keyboardInset > 0 ? 0 : _homeIndicatorInset,
  );
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
}

Future<void> _resetTestView(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(null);
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.view.resetViewPadding();
  tester.view.resetViewInsets();
}

Widget _mergeViewportInsets(BuildContext context, Widget child) {
  final MediaQueryData routeMq = MediaQuery.of(context);
  final MediaQueryData viewMq = MediaQueryData.fromView(View.of(context));
  return MediaQuery(
    data: routeMq.copyWith(
      viewInsets: viewMq.viewInsets,
      viewPadding: viewMq.viewPadding,
      padding: routeMq.padding.copyWith(top: viewMq.viewPadding.top),
    ),
    child: child,
  );
}

/// Mirrors overlay-mode sheet hosting in [AppBottomSheet.show].
Widget _wrapOverlaySheet(BuildContext context, Widget child) {
  final MediaQueryData viewMq = MediaQueryData.fromView(View.of(context));
  final double topInset = viewMq.viewPadding.top;
  Widget sheet = wrapScrollControlledBottomSheet(
    context: context,
    maxHeight: _surfaceSize.height - topInset,
    keyboardInsetMode: SheetKeyboardInsetMode.overlay,
    child: _mergeViewportInsets(context, child),
  );
  sheet = MediaQuery.removeViewInsets(
    context: context,
    removeBottom: true,
    child: sheet,
  );
  return SizedBox(
    width: _surfaceSize.width,
    height: _surfaceSize.height,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: sheet,
    ),
  );
}

Future<void> _pumpSubmitResolutionSheet(
  WidgetTester tester, {
  double keyboardInset = 0,
  String? siteTitle,
  SitesRepository? sitesRepository,
  List<XFile>? testInitialPhotos,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  _configureTestView(tester, keyboardInset: keyboardInset);
  await tester.pumpWidget(
    wrapForWidgetTest(
      SizedBox(
        width: _surfaceSize.width,
        height: _surfaceSize.height,
        child: Builder(
          builder: (BuildContext context) => _wrapOverlaySheet(
            context,
            SubmitResolutionSheet(
              siteId: 'site-test',
              siteTitle: siteTitle,
              sitesRepository: sitesRepository,
              testInitialPhotos: testInitialPhotos,
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _focusNoteField(WidgetTester tester, {bool settle = true}) async {
  final Finder notesField = find.byType(TextFormField);
  await tester.ensureVisible(notesField);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.tap(notesField);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
  await tester.pump(const Duration(milliseconds: 300));
}

Rect _submitButtonRect(WidgetTester tester) {
  return tester.getRect(
    find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.text('Submit for review'),
    ),
  );
}

double _sheetDecoratedHeight(WidgetTester tester) {
  final Finder title = find.text('Confirm cleanup');
  expect(title, findsOneWidget);
  final Finder sheetShell = find.ancestor(
    of: title,
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == AppColors.panelBackground,
    ),
  );
  expect(sheetShell, findsOneWidget);
  return tester.getSize(sheetShell).height;
}

Future<void> _pumpSubmitResolutionSheetViaBottomSheet(
  WidgetTester tester, {
  String? siteTitle,
  double keyboardInset = 0,
  double topInset = 0,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  _configureTestView(
    tester,
    keyboardInset: keyboardInset,
    topInset: topInset,
  );

  await tester.pumpWidget(
    wrapForWidgetTest(
      SizedBox(
        width: _surfaceSize.width,
        height: _surfaceSize.height,
        child: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    SubmitResolutionSheet.show(
                      context,
                      siteId: 'site-test',
                      siteTitle: siteTitle,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder _confirmCleanupSheetShell() {
  return find.ancestor(
    of: find.text('Confirm cleanup'),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == AppColors.panelBackground,
    ),
  );
}

class _FailSubmitSitesRepository implements SitesRepository {
  @override
  Future<List<String>> uploadResolutionPhotos(
    String siteId,
    List<String> filePaths,
  ) async {
    throw AppError.server();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HangingSubmitSitesRepository implements SitesRepository {
  _HangingSubmitSitesRepository(this._uploadCompleter);

  final Completer<List<String>> _uploadCompleter;

  @override
  Future<List<String>> uploadResolutionPhotos(
    String siteId,
    List<String> filePaths,
  ) =>
      _uploadCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(bootstrapWidgetTests);

  testWidgets('note label appears once (not duplicated in field decoration)', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));
    await _pumpSubmitResolutionSheet(tester);

    expect(find.text('Note (optional)'), findsOneWidget);
    expect(find.text('Anything else we should know?'), findsOneWidget);
  });

  testWidgets('note field keeps focus after tap and rebuild', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));
    await _pumpSubmitResolutionSheet(tester);

    final Finder notesField = find.byType(TextFormField);
    expect(notesField, findsOneWidget);

    await tester.ensureVisible(notesField);
    await tester.pumpAndSettle();

    await tester.tap(notesField);
    await tester.pump();

    EditableText editableText(WidgetTester t) {
      return t.widget<EditableText>(find.byType(EditableText));
    }

    expect(editableText(tester).focusNode.hasFocus, isTrue);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(editableText(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('note field keeps focus after simulated keyboard metrics', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));
    await _pumpSubmitResolutionSheet(tester);

    await _focusNoteField(tester);

    EditableText editableText(WidgetTester t) {
      return t.widget<EditableText>(find.byType(EditableText));
    }
    expect(editableText(tester).focusNode.hasFocus, isTrue);

    tester.view.viewInsets = FakeViewPadding(bottom: _keyboardInset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(editableText(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('scroll body carries keyboard padding in overlay mode', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
    );

    final Iterable<SingleChildScrollView> scrollViews =
        tester.widgetList<SingleChildScrollView>(
      find.descendant(
        of: find.byType(SubmitResolutionSheet),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(scrollViews, isNotEmpty);
    final SingleChildScrollView bodyScrollView = scrollViews.first;
    expect(
      (bodyScrollView.padding as EdgeInsets).bottom,
      _keyboardInset,
      reason: 'Overlay host keeps footer at screen bottom; note scroll pads for IME',
    );
  });

  testWidgets('resting sheet expands to notch without overlapping it', (
    WidgetTester tester,
  ) async {
    const double topInset = 59;
    addTearDown(() => _resetTestView(tester));

    await tester.binding.setSurfaceSize(_surfaceSize);
    tester.view.physicalSize = _surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = const FakeViewPadding(
      top: topInset,
      bottom: _homeIndicatorInset,
    );
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpWidget(
      wrapForWidgetTest(
        SizedBox(
          width: _surfaceSize.width,
          height: _surfaceSize.height,
          child: Builder(
            builder: (BuildContext context) => _wrapOverlaySheet(
              context,
              SubmitResolutionSheet(
                siteId: 'site-test',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Offset titleTop = tester.getTopLeft(find.text('Confirm cleanup'));
    expect(
      titleTop.dy,
      greaterThanOrEqualTo(topInset + AppSpacing.xs - 1),
      reason: 'Title must sit below the notch',
    );

    final Finder sheetShell = find.ancestor(
      of: find.text('Confirm cleanup'),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                AppColors.panelBackground,
      ),
    );
    expect(
      tester.getTopLeft(sheetShell).dy,
      closeTo(topInset, 8),
      reason: 'Sheet should extend to the notch edge when fully open',
    );
  });

  testWidgets('footer stays at screen bottom behind keyboard', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
    );

    final double keyboardTop = _surfaceSize.height - _keyboardInset;
    final Rect helpRect = tester.getRect(find.text(_helpText));

    expect(
      helpRect.bottom,
      greaterThan(keyboardTop),
      reason: 'Footer should stay at the screen bottom behind the keyboard',
    );
    expect(
      helpRect.bottom,
      closeTo(_surfaceSize.height, 24),
      reason: 'Footer should remain anchored to the screen bottom edge',
    );
  });

  testWidgets('pinned footer clears home indicator without scrolling', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));
    await _pumpSubmitResolutionSheet(tester);

    final double safeBottom = _surfaceSize.height - _homeIndicatorInset;
    final Rect submitRect = _submitButtonRect(tester);
    final Rect helpRect = tester.getRect(find.text(_helpText));
    expect(
      submitRect.bottom,
      lessThanOrEqualTo(safeBottom),
      reason: 'Submit CTA must sit above the home indicator',
    );
    expect(
      helpRect.bottom,
      lessThanOrEqualTo(safeBottom),
      reason: 'Help text must sit above the home indicator',
    );
  });

  testWidgets('sheet keeps pinned footer at bottom of expanded layout', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      siteTitle: _longSiteTitle,
    );

    final Rect noteFieldRect = tester.getRect(find.byType(TextFormField));
    final Rect submitRect = _submitButtonRect(tester);
    expect(
      submitRect.top,
      greaterThan(noteFieldRect.bottom),
      reason: 'Submit stays pinned below the scroll body',
    );
  });

  testWidgets('resting sheet shows large empty photo card in scroll body', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      siteTitle: _longSiteTitle,
    );

    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text(_longSiteSubtitle), findsOneWidget);
    expect(find.text('Tap to review photo'), findsNothing);
  });

  testWidgets('keyboard open keeps large empty photo card', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
    );

    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Add'), findsNothing);
    expect(find.text('Tap to review photo'), findsNothing);
  });

  testWidgets('subtitle stays visible when note is focused', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      siteTitle: _longSiteTitle,
    );

    expect(find.text(_longSiteSubtitle), findsOneWidget);

    await _focusNoteField(tester);

    expect(find.text(_longSiteSubtitle), findsOneWidget);
  });

  testWidgets('footer does not lift when keyboard opens', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
    );

    final Rect submitBefore = _submitButtonRect(tester);
    expect(find.byType(AnimatedPadding), findsNothing);

    await _focusNoteField(tester);

    final Rect submitAfter = _submitButtonRect(tester);
    expect(
      submitAfter.bottom,
      closeTo(submitBefore.bottom, 2),
      reason: 'Overlay host must not lift the pinned footer when keyboard opens',
    );
    expect(
      submitAfter.bottom,
      greaterThan(_surfaceSize.height - _keyboardInset),
      reason: 'Footer should stay behind the keyboard at the screen bottom',
    );
  });

  testWidgets('scaffold does not use padFooterForKeyboard lift', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheetViaBottomSheet(tester);

    final AppSheetScaffold scaffold =
        tester.widget<AppSheetScaffold>(find.byType(AppSheetScaffold));
    expect(scaffold.padFooterForKeyboard, isFalse);
    expect(scaffold.shrinkForKeyboard, isFalse);

    tester.view.viewInsets = FakeViewPadding(bottom: _keyboardInset);
    await tester.pump();

    expect(find.byType(AnimatedPadding), findsNothing);
  });

  testWidgets('real modal keeps footer at screen bottom behind keyboard', (
    WidgetTester tester,
  ) async {
    const double topInset = 59;
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheetViaBottomSheet(
      tester,
      keyboardInset: _keyboardInset,
      topInset: topInset,
    );

    await _focusNoteField(tester);

    final double keyboardTop = _surfaceSize.height - _keyboardInset;
    final Rect helpRect = tester.getRect(find.text(_helpText));
    final Rect shellRect = tester.getRect(_confirmCleanupSheetShell());
    expect(
      helpRect.bottom,
      greaterThan(keyboardTop),
      reason: 'Real modal path must keep footer behind the keyboard',
    );
    expect(
      helpRect.bottom,
      closeTo(_surfaceSize.height, 24),
      reason: 'Footer should stay anchored to the screen bottom',
    );
    expect(
      shellRect.bottom,
      closeTo(helpRect.bottom, 4),
      reason: 'Sheet chrome should end at the footer block',
    );
  });

  testWidgets('real modal sheet top clears notch when keyboard is open', (
    WidgetTester tester,
  ) async {
    const double topInset = 59;
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheetViaBottomSheet(
      tester,
      keyboardInset: _keyboardInset,
      topInset: topInset,
    );

    await _focusNoteField(tester);

    final Rect sheetRect = tester.getRect(_confirmCleanupSheetShell());
    expect(
      sheetRect.top,
      greaterThanOrEqualTo(topInset - 2),
      reason: 'Overlay sheet must stay below the notch when keyboard opens',
    );
    expect(
      sheetRect.top,
      lessThan(topInset + 24),
      reason: 'Sheet should expand toward the notch without bleeding into it',
    );
  });

  testWidgets('subtitle stays visible while keyboard is open', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      siteTitle: _longSiteTitle,
      keyboardInset: _keyboardInset,
    );

    expect(find.text(_longSiteSubtitle), findsOneWidget);
  });

  testWidgets('pinned footer stays at screen bottom behind keyboard', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
      siteTitle: _longSiteTitle,
    );

    await _focusNoteField(tester);

    final double keyboardTop = _surfaceSize.height - _keyboardInset;
    final Rect submitRect = _submitButtonRect(tester);

    expect(
      submitRect.bottom,
      greaterThan(keyboardTop),
      reason: 'Pinned footer should stay at the screen bottom behind the keyboard',
    );
  });

  testWidgets('help text stays visible while keyboard is open', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
    );

    expect(find.text(_helpText), findsOneWidget);
  });

  testWidgets('note field fully visible above footer when keyboard is open', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
    );

    await _focusNoteField(tester);

    final Rect noteLabelRect = tester.getRect(find.text('Note (optional)'));
    final Rect noteFieldRect = tester.getRect(find.byType(TextFormField));
    final Rect submitRect = _submitButtonRect(tester);
    final double keyboardTop = _surfaceSize.height - _keyboardInset;

    expect(noteLabelRect.top, greaterThan(0));
    expect(
      noteFieldRect.bottom,
      lessThanOrEqualTo(keyboardTop),
      reason: 'Note field must stay visible above the keyboard',
    );
    expect(
      submitRect.bottom,
      greaterThan(keyboardTop),
      reason: 'Pinned footer stays behind the keyboard while note remains visible',
    );
    expect(
      noteFieldRect.height,
      greaterThan(40),
      reason: 'Note field should not be clipped to a sliver',
    );
    expect(
      noteLabelRect.top,
      lessThan(noteFieldRect.top),
      reason: 'Note label should appear above the note field',
    );
  });

  testWidgets('does not overflow when keyboard is open and note is focused', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
    );

    await _focusNoteField(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps expanded add card when a photo is already attached', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      testInitialPhotos: <XFile>[XFile('/tmp/photo-a.jpg')],
      settle: false,
    );

    expect(find.text('1 of 5 photos attached'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Camera or library'), findsOneWidget);
    expect(find.text('Add'), findsNothing);

    final Rect addCardRect = tester.getRect(find.text('Add a photo'));
    final Rect thumbnailRect = tester.getRect(find.byIcon(Icons.check_rounded));
    expect(
      addCardRect.top,
      lessThan(thumbnailRect.top),
      reason: 'Add card should appear above attached photo thumbnails',
    );
  });

  testWidgets('note field visible above keyboard when photo is attached', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      keyboardInset: _keyboardInset,
      testInitialPhotos: <XFile>[XFile('/tmp/photo-a.jpg')],
      settle: false,
    );

    await _focusNoteField(tester, settle: false);
    await tester.pump(AppMotion.medium);

    expect(find.text('Add a photo'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    final Rect noteLabelRect = tester.getRect(find.text('Note (optional)'));
    final Rect noteFieldRect = tester.getRect(find.byType(TextFormField));
    final double keyboardTop = _surfaceSize.height - _keyboardInset;

    expect(noteLabelRect.top, greaterThan(0));
    expect(
      noteFieldRect.bottom,
      lessThanOrEqualTo(keyboardTop),
      reason: 'Note field must stay visible above the keyboard with photos attached',
    );
    expect(
      noteLabelRect.top,
      lessThan(noteFieldRect.top),
      reason: 'Note label should appear above the note field',
    );
  });

  testWidgets('close button stays visible during submit (no header spinner)', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    final Completer<List<String>> uploadCompleter = Completer<List<String>>();
    await _pumpSubmitResolutionSheet(
      tester,
      sitesRepository: _HangingSubmitSitesRepository(uploadCompleter),
      testInitialPhotos: <XFile>[XFile('/tmp/photo-a.jpg')],
      settle: false,
    );

    await tester.tap(find.text('Submit for review'));
    await tester.pump();

    expect(find.byIcon(Icons.sync_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsWidgets);
  });

  testWidgets('submit failure shows inline banner and keeps photo section', (
    WidgetTester tester,
  ) async {
    addTearDown(() => _resetTestView(tester));

    await _pumpSubmitResolutionSheet(
      tester,
      sitesRepository: _FailSubmitSitesRepository(),
      testInitialPhotos: <XFile>[XFile('/tmp/photo-a.jpg')],
      settle: false,
    );

    await tester.tap(find.text('Submit for review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppErrorView), findsNothing);
    expect(find.byType(ApiErrorBanner), findsOneWidget);
    expect(
      find.text(
        "We couldn't submit your cleanup photos. Check your connection and try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('1 of 5 photos attached'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Submit for review'), findsOneWidget);
  });
}
