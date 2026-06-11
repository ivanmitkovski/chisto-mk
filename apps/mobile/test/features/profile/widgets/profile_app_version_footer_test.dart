import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_profile/src/presentation/providers/profile_app_version_provider.dart';
import 'package:feature_profile/src/presentation/widgets/profile_app_version_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('shows localized version label when provider resolves', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileAppVersionProvider.overrideWith(
            (Ref ref) => Future<String>.value('1.0.0'),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: ProfileAppVersionFooter()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version 1.0.0'), findsOneWidget);
  });
}
