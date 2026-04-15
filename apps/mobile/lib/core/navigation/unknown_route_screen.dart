import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Shown when [Navigator] requests an unknown named route (bad deep link, typo, stale link).
class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({
    super.key,
    this.attemptedRouteName,
  });

  /// Raw [RouteSettings.name] from the failed navigation (may be null).
  final String? attemptedRouteName;

  void _continueToApp(BuildContext context) {
    final bool authed = ServiceLocator.instance.authState.isAuthenticated;
    final String target = authed ? AppRoutes.home : AppRoutes.onboarding;
    Navigator.of(context).pushNamedAndRemoveUntil(
      target,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? rawName = attemptedRouteName?.trim();
    final String debugRouteLabel =
        (rawName == null || rawName.isEmpty) ? '?' : rawName;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              Text(
                l10n.unknownRouteTitle,
                style: AppTypography.emptyStateTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.unknownRouteMessage,
                style: AppTypography.emptyStateSubtitle.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.unknownRouteDebugRoute(debugRouteLabel),
                  style: AppTypography.cardSubtitle,
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: l10n.unknownRouteContinueButton,
                onPressed: () => _continueToApp(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
