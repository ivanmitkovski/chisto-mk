import 'package:chisto_mobile/features/home/presentation/widgets/map/map_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TileLoadingOverlay exposes map loading semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
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
        home: Scaffold(body: EmptyFilterOverlay(onResetFilters: () {})),
      ),
    );

    expect(find.text('No sites match your filters'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);
  });
}
