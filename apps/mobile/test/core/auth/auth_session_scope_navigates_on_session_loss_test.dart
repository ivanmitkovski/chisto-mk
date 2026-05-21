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
    'onAuthUnauthorized navigates to sign-in when session already cleared on app content',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: AppBootstrap.instance.providerContainer,
          child: MaterialApp(
            navigatorKey: appRootNavigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routes: <String, WidgetBuilder>{
              '/content': (_) => const Scaffold(body: Text('app-content')),
              AppRoutes.signIn: (_) => const Scaffold(body: Text('sign-in-gate')),
            },
            initialRoute: '/content',
            builder: (BuildContext context, Widget? child) {
              return AuthSessionScope(child: child ?? const SizedBox.shrink());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('app-content'), findsOneWidget);

      AppBootstrap.instance.onAuthUnauthorized?.call();
      await tester.pumpAndSettle();

      expect(find.text('sign-in-gate'), findsOneWidget);
      expect(find.text('app-content'), findsNothing);
    },
  );
}
