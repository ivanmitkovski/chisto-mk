import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/features/home/presentation/widgets/map/map_toolbar.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('renders search and filter controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
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
