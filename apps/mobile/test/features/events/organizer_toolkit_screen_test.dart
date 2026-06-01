import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('OrganizerToolkitScreen shows eight chapters before quiz CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapForWidgetTest(const OrganizerToolkitScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Plan ahead'), findsOneWidget);

    for (int i = 0; i < 7; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Evidence and honest impact'), findsOneWidget);
    expect(find.text('Take the quiz'), findsOneWidget);
  });
}
