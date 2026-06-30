import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_profile/src/presentation/providers/profile_app_version_provider.dart';
import 'package:feature_profile/src/presentation/widgets/profile_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfileSettingsSection golden en', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ProviderContainer container = ProviderContainer(
      parent: AppBootstrap.instance.providerContainer,
      overrides: <Override>[
        profileAppVersionProvider.overrideWith(
          (Ref ref) => Future<String>.value('1.0.0'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 720),
              devicePixelRatio: 1,
              textScaler: TextScaler.linear(1),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: ProfileSettingsSection(
                  languageListSubtitle: 'English',
                  onGeneralInfoTap: _noop,
                  onLanguageTap: _noop,
                  onPasswordTap: _noop,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProfileSettingsSection),
      matchesGoldenFile('__goldens__/profile_settings_section_en.png'),
    );
  });
}

void _noop() {}
