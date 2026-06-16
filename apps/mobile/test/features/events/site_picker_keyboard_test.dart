import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:feature_events/src/data/event_site_resolver.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_sites_map.dart';
import 'package:feature_events/src/presentation/widgets/create_event/site_picker_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

const Size _surfaceSize = Size(390, 844);
const double _keyboardInset = 300;

List<EventSiteSummary> _testSites() {
  return const <EventSiteSummary>[
    EventSiteSummary(
      id: 's1',
      title: 'Near park',
      description: 'Central area',
      distanceKm: 2.5,
      imageUrl: '',
      latitude: 41.998,
      longitude: 21.431,
    ),
    EventSiteSummary(
      id: 's2',
      title: 'Testqa',
      description: 'Remote site',
      distanceKm: 66.8,
      imageUrl: '',
      latitude: 41.5,
      longitude: 21.2,
    ),
  ];
}

Widget _wrapSitePicker({
  required List<EventSiteSummary> sites,
  SheetKeyboardInsetMode keyboardInsetMode = SheetKeyboardInsetMode.overlay,
  bool initialShowMapTab = false,
}) {
  // Mirrors the keyboard-inset wiring of feedback_sheet_keyboard_inset_test:
  // the host MediaQuery carries size only, while the keyboard inset is read from
  // the view (set via tester.view.viewInsets) and re-applied to the sheet child.
  return wrapForWidgetTest(
    MediaQuery(
      data: const MediaQueryData(size: _surfaceSize),
      child: Builder(
        builder: (BuildContext context) {
          final MediaQueryData viewMq = MediaQueryData.fromView(
            View.of(context),
          );
          final Widget body = SitePickerSheet(
            allSites: sites,
            selectedSiteId: null,
            initialShowMapTab: initialShowMapTab,
            onSelect: (_) {},
            onClose: () {},
          );

          Widget sheet = wrapScrollControlledBottomSheet(
            context: context,
            keyboardInsetMode: keyboardInsetMode,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: viewMq.viewInsets,
                viewPadding: viewMq.viewPadding,
              ),
              child: body,
            ),
          );

          if (keyboardInsetMode == SheetKeyboardInsetMode.overlay) {
            sheet = MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: sheet,
            );
          }

          return Align(
            alignment: Alignment.bottomCenter,
            child: sheet,
          );
        },
      ),
    ),
  );
}

double _sheetDecoratedHeight(WidgetTester tester) {
  final Finder title = find.text('Choose site');
  expect(title, findsOneWidget);
  final Finder decorated = find.ancestor(
    of: title,
    matching: find.byType(DecoratedBox),
  );
  expect(decorated, findsOneWidget);
  return tester.getSize(decorated).height;
}

void main() {
  setUpAll(bootstrapWidgetTests);

  testWidgets('overlay site picker adapts its height when the keyboard opens', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    tester.view.physicalSize = _surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 0);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        keyboardInsetMode: SheetKeyboardInsetMode.overlay,
      ),
    );
    await tester.pumpAndSettle();

    final double closedHeight = _sheetDecoratedHeight(tester);
    expect(
      closedHeight,
      greaterThan(_surfaceSize.height * 0.82),
      reason: 'Without a keyboard the sheet uses ~85% of the screen height',
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardInset);
    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        keyboardInsetMode: SheetKeyboardInsetMode.overlay,
      ),
    );
    await tester.pumpAndSettle();

    final double openHeight = _sheetDecoratedHeight(tester);
    expect(
      openHeight,
      lessThan(closedHeight),
      reason: 'Sheet shrinks to fit above the keyboard when it opens',
    );
    expect(
      openHeight,
      greaterThan(_surfaceSize.height * 0.4),
      reason: 'Sheet stays usable while the keyboard is open',
    );
  });

  testWidgets('last site row can be scrolled into view with the keyboard open', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    tester.view.physicalSize = _surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardInset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
      ),
    );
    await tester.pumpAndSettle();

    final Finder lastRow = find.text('Testqa');
    expect(lastRow, findsOneWidget);

    // With the keyboard open the list reserves bottom padding equal to the
    // inset, so the last row is never permanently hidden — it can be scrolled
    // into the visible sheet area.
    await tester.dragUntilVisible(
      lastRow,
      find.byType(Scrollable).last,
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    expect(lastRow, findsOneWidget);
    final Rect rowRect = tester.getRect(lastRow);
    expect(
      rowRect.bottom,
      lessThanOrEqualTo(_surfaceSize.height),
      reason: 'Last list row scrolls into the visible sheet area',
    );
  });

  testWidgets('map tab collapses map while keyboard is open', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    tester.view.physicalSize = _surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 0);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        initialShowMapTab: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventSitesMap), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardInset);
    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        initialShowMapTab: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventSitesMap), findsNothing);
    expect(find.text('Testqa'), findsOneWidget);
  });
}
