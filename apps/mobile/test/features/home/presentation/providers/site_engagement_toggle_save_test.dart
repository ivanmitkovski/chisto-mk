import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggleSave returns notAuthenticated when signed out', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ServiceLocator.instance.initialize(config: AppConfig.local);
    addTearDown(ServiceLocator.instance.reset);

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final SiteEngagementOutcome outcome = await container
        .read(siteEngagementNotifierProvider('550e8400-e29b-41d4-a716-446655440000')
            .notifier)
        .toggleSave();
    expect(outcome.kind, SiteEngagementOutcomeKind.notAuthenticated);
  });
}
