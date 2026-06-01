import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:feature_events/src/presentation/widgets/organizer_checkin/organizer_checkin_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'OrganizerCheckInHeader shows title below toolbar row with trailing',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: OrganizerCheckInHeader(
              title: 'River cleanup',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.pause_circle_outline),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('River cleanup'), findsOneWidget);
      expect(find.byType(IconButton), findsNWidgets(3));
      expect(
        tester.getTopLeft(find.text('River cleanup')).dy,
        greaterThan(tester.getTopLeft(find.byType(AppBackButton)).dy),
      );
    },
  );

  testWidgets('OrganizerCheckInHeader works without trailing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: OrganizerCheckInHeader(title: 'Check-in')),
      ),
    );

    expect(find.text('Check-in'), findsOneWidget);
  });
}
