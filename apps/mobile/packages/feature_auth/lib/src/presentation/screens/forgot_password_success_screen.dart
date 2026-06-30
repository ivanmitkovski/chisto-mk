import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ForgotPasswordSuccessScreen extends StatelessWidget {
  const ForgotPasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              const Spacer(),
              Semantics(
                label: l10n.authPasswordResetSuccessTitle,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.authPasswordResetSuccessTitle,
                textAlign: TextAlign.center,
                style: AppTypography.authScreenTitle(
                  Theme.of(context).textTheme,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.authPasswordResetSuccessBody,
                textAlign: TextAlign.center,
                style: AppTypography.authScreenSubtitle(
                  Theme.of(context).textTheme,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: l10n.authBackToSignIn,
                child: AppButton.primary(
                  label: l10n.authBackToSignIn,
                  onPressed: AppNavigation.goSignIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
