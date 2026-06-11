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
  required double keyboardInset,
  SheetKeyboardInsetMode keyboardInsetMode = SheetKeyboardInsetMode.overlay,
  bool initialShowMapTab = false,
}) {
  return wrapForWidgetTest(
    MediaQuery(
      data: MediaQueryData(
        size: _surfaceSize,
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: Builder(
        builder: (BuildContext context) {
          final MediaQueryData sheetMediaQuery = MediaQuery.of(context);
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
            child: keyboardInsetMode == SheetKeyboardInsetMode.overlay
                ? MediaQuery(data: sheetMediaQuery, child: body)
                : body,
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

  testWidgets('overlay mode keeps site picker sheet height stable with keyboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        keyboardInset: _keyboardInset,
        keyboardInsetMode: SheetKeyboardInsetMode.overlay,
      ),
    );
    await tester.pumpAndSettle();

    final double overlayHeight = _sheetDecoratedHeight(tester);
    expect(
      overlayHeight,
      greaterThan(_surfaceSize.height * 0.82),
      reason: 'Sheet should stay near 85% screen height when keyboard overlays',
    );

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        keyboardInset: _keyboardInset,
        keyboardInsetMode: SheetKeyboardInsetMode.lift,
      ),
    );
    await tester.pumpAndSettle();

    final double liftHeight = _sheetDecoratedHeight(tester);
    expect(
      overlayHeight,
      greaterThan(liftHeight + 100),
      reason: 'Overlay mode should not shrink the sheet like lift mode',
    );
  });

  testWidgets('last site row can scroll above simulated keyboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        keyboardInset: _keyboardInset,
      ),
    );
    await tester.pumpAndSettle();

    final Finder lastRow = find.text('Testqa');
    expect(lastRow, findsOneWidget);

    await tester.dragUntilVisible(
      lastRow,
      find.byType(Scrollable),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    final double keyboardTop = _surfaceSize.height - _keyboardInset;
    final Rect rowRect = tester.getRect(lastRow);
    expect(
      rowRect.bottom,
      lessThan(keyboardTop),
      reason: 'Last list row should scroll above the keyboard',
    );
  });

  testWidgets('map tab collapses map while keyboard is open', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        keyboardInset: 0,
        initialShowMapTab: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventSitesMap), findsOneWidget);

    await tester.pumpWidget(
      _wrapSitePicker(
        sites: _testSites(),
        keyboardInset: _keyboardInset,
        initialShowMapTab: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventSitesMap), findsNothing);
    expect(find.text('Testqa'), findsOneWidget);
  });
}
