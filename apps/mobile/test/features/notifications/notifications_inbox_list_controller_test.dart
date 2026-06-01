import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_notifications/src/presentation/notifications_inbox/notifications_inbox_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopRef implements WidgetRef {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('forceLoadEndedWithError clears loading skeleton state', () {
    final NotificationsInboxListController controller =
        NotificationsInboxListController(
          ref: _NoopRef(),
          onStateChanged: () {},
        );

    expect(controller.isLoading, isTrue);

    controller.forceLoadEndedWithError(
      l10n: lookupAppLocalizations(const Locale('en')),
      error: StateError('localizations unavailable'),
    );

    expect(controller.isLoading, isFalse);
    expect(controller.loadErrorMessage, isNotNull);
  });
}
