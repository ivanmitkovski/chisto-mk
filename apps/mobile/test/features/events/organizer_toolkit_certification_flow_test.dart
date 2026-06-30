import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_events/src/presentation/navigation/organizer_certification_navigation.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_quiz_screen.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    AppBootstrap.instance.authState.setAuthenticated(
      userId: 'u1',
      displayName: 'Tester',
      organizerCertifiedAt: null,
      syncOrganizerCertifiedAt: true,
    );
  });

  testWidgets(
    'certification during quiz does not pop quiz before user continues',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForWidgetTest(
          Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(
                            name: organizerCertificationToolkitRouteName,
                          ),
                          builder: (_) => const OrganizerToolkitScreen(),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 7; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Take the quiz'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(OrganizerQuizScreen), findsOneWidget);

      AppBootstrap.instance.authState.markOrganizerCertified(
        DateTime(2026, 6, 1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(OrganizerQuizScreen), findsOneWidget);
    },
  );
}
