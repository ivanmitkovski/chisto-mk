import 'package:feature_events/src/presentation/navigation/organizer_certification_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dismissOrganizerCertificationFlow removes quiz and toolkit overlays',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
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
                          builder: (_) => const Scaffold(
                            body: Center(child: Text('toolkit_overlay')),
                          ),
                        ),
                      );
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(
                            name: organizerCertificationQuizRouteName,
                          ),
                          builder: (_) => const Scaffold(
                            body: Center(child: Text('quiz_overlay')),
                          ),
                        ),
                      );
                    },
                    child: const Text('open_flow'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open_flow'));
      await tester.pumpAndSettle();

      expect(find.text('quiz_overlay'), findsOneWidget);

      dismissOrganizerCertificationFlow(
        tester.element(find.text('quiz_overlay')),
      );
      await tester.pumpAndSettle();

      expect(find.text('quiz_overlay'), findsNothing);
      expect(find.text('toolkit_overlay'), findsNothing);
      expect(find.text('open_flow'), findsOneWidget);
    },
  );
}
