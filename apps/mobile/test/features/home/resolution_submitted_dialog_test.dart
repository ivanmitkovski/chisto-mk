import 'package:feature_home/src/presentation/widgets/resolution_submitted_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(bootstrapWidgetTests);

  testWidgets('ResolutionSubmittedDialog shows review copy and actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () => ResolutionSubmittedDialog.show(context),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted for review'), findsOneWidget);
    expect(find.text('View my reports'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('admin'), findsOneWidget);
  });
}
