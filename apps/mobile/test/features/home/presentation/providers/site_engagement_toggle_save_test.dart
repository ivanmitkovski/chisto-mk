import 'package:chisto_mobile/features/home/presentation/providers/site_engagement_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('toggleSave returns notAuthenticated when signed out', () async {

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final SiteEngagementOutcome outcome = await container
        .read(siteEngagementNotifierProvider('550e8400-e29b-41d4-a716-446655440000')
            .notifier)
        .toggleSave();
    expect(outcome.kind, SiteEngagementOutcomeKind.notAuthenticated);
  });
}
