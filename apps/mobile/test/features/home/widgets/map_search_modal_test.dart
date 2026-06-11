import 'dart:ui';

import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/map_derived_providers.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/widgets/map/map_sheet_launcher.dart';
import 'package:feature_home/src/presentation/widgets/map/search_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/stub_sites_repository.dart';
import '../support/test_pollution_site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders preview, filters by query, and submits first result', (
    WidgetTester tester,
  ) async {
    final PollutionSite alpha = buildTestPollutionSite(id: 'alpha');
    final PollutionSite beta = buildTestPollutionSite(id: 'beta');
    PollutionSite? tappedSite;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mapSearchLocalPoolProvider.overrideWith((Ref ref) {
            return <PollutionSite>[alpha, beta];
          }),
          sitesRepositoryProvider.overrideWithValue(StubSitesRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: MapSearchModal(
              onResultTap: (PollutionSite site) => tappedSite = site,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('On this map'), findsOneWidget);
    expect(find.text('Site alpha'), findsOneWidget);
    expect(find.text('Site beta'), findsOneWidget);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'x');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.text('Keep typing'), findsOneWidget);
    expect(find.text('No matching sites'), findsNothing);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'alpha');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.text('Site alpha'), findsOneWidget);
    expect(find.text('Site beta'), findsNothing);
    expect(find.text('1 results'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tappedSite?.id, 'alpha');
  });

  testWidgets(
    'shows reset filters action when search is empty under non-default filters',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            mapSearchLocalPoolProvider.overrideWith(
              (Ref ref) => const <PollutionSite>[],
            ),
            mapFilterNotifierProvider.overrideWith(MapFilterNotifier.new),
            sitesRepositoryProvider.overrideWithValue(StubSitesRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: MapSearchModal(onResultTap: (_) {}, onDismiss: () {}),
            ),
          ),
        ),
      );

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MapSearchModal)),
      );
      container.read(mapFilterNotifierProvider.notifier).setGeoAreaId('skopje');

      await tester.enterText(find.byType(CupertinoSearchTextField), 'zz');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(find.text('No matching sites'), findsOneWidget);
      expect(find.text('Reset filters'), findsOneWidget);
    },
  );

  testWidgets(
    'map sheet keeps full body height when the keyboard opens (single inset)',
    (WidgetTester tester) async {
      const double screenHeight = 844;
      const double keyboardInset = 336;
      const double keyboardTop = screenHeight - keyboardInset;

      await tester.binding.setSurfaceSize(const Size(390, screenHeight));
      tester.view.physicalSize = const Size(390, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            mapSearchLocalPoolProvider.overrideWith((Ref ref) {
              return <PollutionSite>[
                buildTestPollutionSite(id: 'alpha'),
                buildTestPollutionSite(id: 'beta'),
              ];
            }),
            sitesRepositoryProvider.overrideWithValue(StubSitesRepository()),
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
                        showMapBottomSheet<void>(
                          context: context,
                          builder: (BuildContext sheetContext) =>
                              MapSearchModal(
                                onResultTap: (_) {},
                                onDismiss: () {},
                              ),
                        );
                      },
                      child: const Text('Open search'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open search'));
      await tester.pumpAndSettle();

      // The modal autofocuses its field; simulate the IME opening.
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
      await tester.pumpAndSettle();

      final RenderBox modalBox = tester.renderObject<RenderBox>(
        find.byType(MapSearchModal),
      );
      final double modalBottom = modalBox
          .localToGlobal(Offset(0, modalBox.size.height))
          .dy;

      expect(
        modalBottom,
        closeTo(screenHeight, 8),
        reason: 'Sheet panel stays anchored to the screen bottom; keyboard overlays',
      );

      final RenderBox scrollBox = tester.renderObject<RenderBox>(
        find.byType(CustomScrollView),
      );
      expect(
        scrollBox.localToGlobal(Offset(0, scrollBox.size.height)).dy,
        closeTo(keyboardTop, 8),
        reason: 'Scroll viewport ends flush above the keyboard',
      );
      expect(
        modalBox.size.height,
        greaterThan(keyboardTop - 100),
        reason: 'Keyboard inset must be applied once inside the scroll body',
      );

      // The first preview tile stays fully visible above the keyboard.
      final RenderBox tileBox = tester.renderObject<RenderBox>(
        find.text('Site alpha'),
      );
      expect(
        tileBox.localToGlobal(Offset(0, tileBox.size.height)).dy,
        lessThan(keyboardTop),
        reason: 'Preview results remain visible while typing',
      );
    },
  );

  testWidgets('map search title stays below the Dynamic Island notch', (
    WidgetTester tester,
  ) async {
    const double screenHeight = 844;
    const double topInset = 59;

    await tester.binding.setSurfaceSize(const Size(390, screenHeight));
    tester.view.physicalSize = const Size(390, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mapSearchLocalPoolProvider.overrideWith((Ref ref) {
            return <PollutionSite>[buildTestPollutionSite(id: 'alpha')];
          }),
          sitesRepositoryProvider.overrideWithValue(StubSitesRepository()),
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
                      showMapBottomSheet<void>(
                        context: context,
                        builder: (BuildContext sheetContext) =>
                            MapSearchModal(
                              onResultTap: (_) {},
                              onDismiss: () {},
                            ),
                      );
                    },
                    child: const Text('Open search'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open search'));
    await tester.pumpAndSettle();

    final RenderBox titleBox = tester.renderObject<RenderBox>(
      find.text('Search'),
    );
    expect(
      titleBox.localToGlobal(Offset.zero).dy,
      greaterThanOrEqualTo(topInset + AppSpacing.sm - 1),
      reason: 'Search header must start below the notch, like the comments sheet',
    );
  });
}
