import 'package:chisto_mobile/features/home/presentation/widgets/map/map_overlays.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TileLoadingOverlay exposes map loading semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: Stack(
            children: <Widget>[TileLoadingOverlay(showLoading: true)],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Loading map'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('EmptyFilterOverlay shows empty-state content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: EmptyFilterOverlay(onResetFilters: () {})),
      ),
    );

    expect(find.text('No sites match your filters'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);
  });
}
