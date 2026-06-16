import 'dart:ui';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/presentation/widgets/comments_bottom_sheet.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_sheet_drag.dart';
import 'package:feature_home/src/presentation/widgets/comments/comments_thread_empty_state.dart';
import 'package:feature_home/src/presentation/widgets/site_comments_modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('comments modal overlay model when keyboard is open', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;
    const double topInset = 59;
    const double keyboardInset = 336;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    tester.view.physicalSize = const Size(390, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authStateProvider.overrideWith((Ref ref) {
            final AuthState state = AuthState();
            state.setAuthenticated(userId: 'u-test', displayName: 'Tester');
            return state;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showPollutionSiteCommentsModalBottomSheet(
                        context,
                        builder:
                            (
                              BuildContext sheetContext,
                              ScrollController scrollController,
                              DraggableScrollableController sheetController,
                              CommentsSheetSizeConfig sizeConfig,
                            ) {
                              return CommentsBottomSheet(
                                comments: const <Comment>[],
                                siteTitle: 'Recycling Container',
                                scrollController: scrollController,
                                sheetController: sheetController,
                                sheetSizeConfig: sizeConfig,
                              );
                            },
                      );
                    },
                    child: const Text('Open comments'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open comments'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final RenderBox sheetBox = tester.renderObject<RenderBox>(
      find.byType(AppResizableSheet),
    );
    final double keyboardTop = screenHeight - keyboardInset;

    expect(
      sheetBox.localToGlobal(Offset.zero).dy,
      closeTo(topInset, 8),
      reason: 'Sheet should expand to notch-safe max when keyboard opens',
    );

    expect(
      sheetBox.localToGlobal(Offset(0, sheetBox.size.height)).dy,
      closeTo(screenHeight, 8),
      reason:
          'Sheet bottom stays anchored at screen bottom (keyboard overlays)',
    );

    expect(find.byType(TextField), findsOneWidget);
    final RenderBox inputBox = tester.renderObject<RenderBox>(
      find.byType(TextField),
    );
    expect(
      inputBox.localToGlobal(Offset.zero).dy + inputBox.size.height,
      lessThanOrEqualTo(keyboardTop + 8),
      reason: 'Composer lifts by viewInsets above the keyboard',
    );
  });

  testWidgets('comment composer keeps focus when keyboard opens', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;
    const double topInset = 59;
    const double keyboardInset = 336;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    tester.view.physicalSize = const Size(390, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authStateProvider.overrideWith((Ref ref) {
            final AuthState state = AuthState();
            state.setAuthenticated(userId: 'u-test', displayName: 'Tester');
            return state;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showPollutionSiteCommentsModalBottomSheet(
                        context,
                        builder:
                            (
                              BuildContext sheetContext,
                              ScrollController scrollController,
                              DraggableScrollableController sheetController,
                              CommentsSheetSizeConfig sizeConfig,
                            ) {
                              return CommentsBottomSheet(
                                comments: const <Comment>[],
                                siteTitle: 'Recycling Container',
                                scrollController: scrollController,
                                sheetController: sheetController,
                                sheetSizeConfig: sizeConfig,
                              );
                            },
                      );
                    },
                    child: const Text('Open comments'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open comments'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableBefore = tester.state<EditableTextState>(
      find.byType(EditableText),
    );

    // The IME animates up: metrics change several times before settling.
    tester.view.viewInsets = FakeViewPadding(bottom: 120);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding(bottom: 240);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final EditableTextState editableAfter = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    expect(
      identical(editableBefore, editableAfter),
      isTrue,
      reason:
          'Composer TextField must not be remounted while the keyboard '
          'opens, or the IME connection closes and the keyboard dismisses',
    );

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.focusNode!.hasFocus,
      isTrue,
      reason: 'Composer keeps focus through the keyboard open animation',
    );
  });

  testWidgets('thread area and empty state stay above the keyboard', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;
    const double topInset = 59;
    const double keyboardInset = 336;
    const double keyboardTop = screenHeight - keyboardInset;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    tester.view.physicalSize = const Size(390, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authStateProvider.overrideWith((Ref ref) {
            final AuthState state = AuthState();
            state.setAuthenticated(userId: 'u-test', displayName: 'Tester');
            return state;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showPollutionSiteCommentsModalBottomSheet(
                        context,
                        builder:
                            (
                              BuildContext sheetContext,
                              ScrollController scrollController,
                              DraggableScrollableController sheetController,
                              CommentsSheetSizeConfig sizeConfig,
                            ) {
                              return CommentsBottomSheet(
                                comments: const <Comment>[],
                                siteTitle: 'Recycling Container',
                                scrollController: scrollController,
                                sheetController: sheetController,
                                sheetSizeConfig: sizeConfig,
                              );
                            },
                      );
                    },
                    child: const Text('Open comments'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open comments'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();

    // Ramp the IME up in steps like the platform animation does.
    for (final double step in <double>[80, 200, keyboardInset]) {
      tester.view.viewInsets = FakeViewPadding(bottom: step);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'No layout overflow while sheet and keyboard animate together',
    );

    final RenderBox emptyBox = tester.renderObject<RenderBox>(
      find.byType(CommentsThreadEmptyState),
    );
    final double emptyHeightWhileOpen = emptyBox.size.height;
    expect(
      emptyBox.localToGlobal(Offset(0, emptyHeightWhileOpen)).dy,
      lessThanOrEqualTo(keyboardTop + 1),
      reason:
          'Empty state shrinks above the keyboard instead of sitting '
          'behind it',
    );

    final RenderBox inputBox = tester.renderObject<RenderBox>(
      find.byType(TextField),
    );
    expect(
      inputBox.localToGlobal(Offset(0, inputBox.size.height)).dy,
      lessThanOrEqualTo(keyboardTop + 1),
      reason: 'Composer stays above the keyboard',
    );

    // Keyboard closes: everything returns smoothly with no exception.
    for (final double step in <double>[200, 80, 0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: step);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final RenderBox emptyBoxClosed = tester.renderObject<RenderBox>(
      find.byType(CommentsThreadEmptyState),
    );
    expect(
      emptyBoxClosed.size.height,
      greaterThan(emptyHeightWhileOpen),
      reason: 'Thread area expands back when the keyboard closes',
    );
  });
}
