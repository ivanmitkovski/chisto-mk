import 'package:chisto_mobile/core/auth/auth_session_scope.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/navigation/app_navigator_key.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    AppBootstrap.instance.suppressSessionExpiredMessage = false;
    AppBootstrap.instance.authState.setUnauthenticated();
  });

  testWidgets(
    'armSuppressSessionExpiredWindow suppresses snack on onAuthUnauthorized',
    (WidgetTester tester) async {
      AppBootstrap.instance.armSuppressSessionExpiredWindow();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: AppBootstrap.instance.providerContainer,
          child: MaterialApp(
            navigatorKey: appRootNavigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routes: <String, WidgetBuilder>{
              AppRoutes.signIn: (_) => const Scaffold(body: Text('sign-in-gate')),
            },
            initialRoute: AppRoutes.signIn,
            builder: (BuildContext context, Widget? child) {
              return AuthSessionScope(child: child ?? const SizedBox.shrink());
            },
          ),
        ),
      );
      await tester.pump();

      AppBootstrap.instance.onAuthUnauthorized?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Your session expired. Please sign in again.'),
        findsNothing,
      );
    },
  );
}
