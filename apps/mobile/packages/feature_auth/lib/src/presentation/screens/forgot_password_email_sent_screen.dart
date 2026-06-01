import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_screen_header.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/auth_shell.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ForgotPasswordEmailSentScreen extends StatelessWidget {
  const ForgotPasswordEmailSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return AuthShell(
      header: AuthScreenHeader(
        showBackButton: true,
        title: l10n.authForgotPasswordEmailSentTitle,
        subtitle: l10n.authForgotPasswordEmailSentBody,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: PrimaryButton(
          label: l10n.authSignInCta,
          onPressed: AppNavigation.goSignInAndClearStack,
        ),
      ),
    );
  }
}
