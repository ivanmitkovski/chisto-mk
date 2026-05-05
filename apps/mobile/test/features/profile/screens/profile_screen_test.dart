import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfileScreen mounts under app provider scope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ServiceLocator.instance.providerContainer,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
