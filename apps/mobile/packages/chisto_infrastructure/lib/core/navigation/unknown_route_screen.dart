import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown when [GoRouter] requests an unknown route (bad deep link, typo, stale link).
class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, this.attemptedRouteName});

  /// Raw route path from the failed navigation (may be null).
  final String? attemptedRouteName;

  void _continueToApp(BuildContext context) {
    final bool authed = readRoot(authStateProvider).isAuthenticated;
    if (authed) {
      AppNavigation.navigateToHome();
    } else {
      AppNavigation.goOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? rawName = attemptedRouteName?.trim();
    final String debugRouteLabel = (rawName == null || rawName.isEmpty)
        ? '?'
        : rawName;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Spacer(),
            AppEmptyState(
              icon: Icons.link_off_rounded,
              title: l10n.unknownRouteTitle,
              subtitle: l10n.unknownRouteMessage,
              contentBelowSubtitle: kDebugMode
                  ? Text(
                      l10n.unknownRouteDebugRoute(debugRouteLabel),
                      textAlign: TextAlign.center,
                      style: AppTypography.cardSubtitle(
                        Theme.of(context).textTheme,
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton.primary(
                label: l10n.unknownRouteContinueButton,
                onPressed: () => _continueToApp(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
