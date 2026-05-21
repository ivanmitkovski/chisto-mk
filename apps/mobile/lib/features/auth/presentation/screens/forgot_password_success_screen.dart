import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';

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
                style: AppTypography.authScreenTitle(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.authPasswordResetSuccessBody,
                textAlign: TextAlign.center,
                style: AppTypography.authScreenSubtitle(context),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: l10n.authBackToSignIn,
                child: PrimaryButton(
                  label: l10n.authBackToSignIn,
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (Route<dynamic> route) =>
                          route.settings.name == AppRoutes.signIn,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
