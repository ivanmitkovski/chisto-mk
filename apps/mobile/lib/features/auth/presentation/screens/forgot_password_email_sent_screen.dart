import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/organisms/auth_screen_header.dart';
import 'package:chisto_mobile/shared/widgets/organisms/auth_shell.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';

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
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.signIn,
            (Route<dynamic> r) => false,
          ),
        ),
      ),
    );
  }
}
