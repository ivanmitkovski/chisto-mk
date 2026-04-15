import 'package:chisto_mobile/core/navigation/app_routes.dart'
    show AppRouter, AppRoutes;
import 'package:chisto_mobile/core/navigation/unknown_route_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unknown named route builds UnknownRouteScreen not SignInScreen', (
    WidgetTester tester,
  ) async {
    final MaterialPageRoute<void> generated =
        AppRouter.onGenerateRoute(const RouteSettings(name: '/route-that-does-not-exist'))
            as MaterialPageRoute<void>;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) => generated.builder(context),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(UnknownRouteScreen), findsOneWidget);
    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('sign-in route builds SignInScreen', (WidgetTester tester) async {
    final MaterialPageRoute<void> generated =
        AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.signIn))
            as MaterialPageRoute<void>;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) => generated.builder(context),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
