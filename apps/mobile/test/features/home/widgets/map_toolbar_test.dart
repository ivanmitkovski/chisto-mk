import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/widgets/map/map_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('renders search and filter controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: MapToolbar(
              visibleCount: 3,
              rotationLocked: false,
              rotationDegrees: 10,
              onOpenFilters: _noop,
              onOpenSearch: _noop,
              onResetRotation: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MapToolbar), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}

void _noop() {}
