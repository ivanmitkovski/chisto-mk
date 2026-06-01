import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_auth/src/data/eula_acceptance_store.dart';
import 'package:feature_auth/src/presentation/widgets/community_guidelines_acceptance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';
import 'support/fake_auth_repository.dart';

void main() {
  const String testUserId = 'user_dialog_test';

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() async {
    await EulaAcceptanceStore(
      AppBootstrap.instance.preferences,
    ).clearAllForTests();
    AppBootstrap.instance.overrideAuthRepositoryForTests(
      FakeAuthRepository(isAuthenticated: true, currentUserId: testUserId)
        ..requiresTermsAcceptance = true,
    );
  });

  testWidgets('shows design-system modal and persists on accept', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            return TextButton(
              onPressed: () => showCommunityGuidelinesAcceptanceDialog(
                context,
                ref: ref,
                userId: testUserId,
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Community guidelines'), findsOneWidget);
    expect(find.text('I agree'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('I agree'));
    await tester.pumpAndSettle();

    expect(find.text('Community guidelines'), findsNothing);
    expect(
      await EulaAcceptanceStore(
        AppBootstrap.instance.preferences,
      ).hasAcceptedForUser(testUserId),
      isTrue,
    );
  });

  testWidgets('cancel returns without persisting acceptance', (tester) async {
    bool? result;
    await tester.pumpWidget(
      wrapForWidgetTest(
        Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            return TextButton(
              onPressed: () async {
                result = await showCommunityGuidelinesAcceptanceDialog(
                  context,
                  ref: ref,
                  userId: testUserId,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(
      await EulaAcceptanceStore(
        AppBootstrap.instance.preferences,
      ).hasAcceptedForUser(testUserId),
      isFalse,
    );
  });
}
