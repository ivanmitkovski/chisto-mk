import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/data/eula_acceptance_store.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blocking community-guidelines acceptance (App Store UGC 1.2).
///
/// Returns `true` if the user accepted and persistence succeeded.
Future<bool> showCommunityGuidelinesAcceptanceDialog(
  BuildContext context, {
  required WidgetRef ref,
  required String userId,
}) async {
  final bool? accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.black.withValues(alpha: 0.45),
    builder: (BuildContext ctx) => _CommunityGuidelinesAcceptanceDialog(
      termsUrl: ref.read(appConfigProvider).termsUrl,
      userId: userId,
    ),
  );
  return accepted ?? false;
}

class _CommunityGuidelinesAcceptanceDialog extends ConsumerWidget {
  const _CommunityGuidelinesAcceptanceDialog({
    required this.termsUrl,
    required this.userId,
  });

  final String termsUrl;
  final String userId;

  Future<void> _openTerms() async {
    final Uri uri = Uri.parse(termsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final TextStyle bodyStyle = AppTypography.textTheme.bodyMedium!.copyWith(
      color: AppColors.textSecondary,
      height: 1.45,
    );

    return ReportModalDialog(
      title: l10n.profileEulaTitle,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: l10n.profileEulaAccept,
            onPressed: () async {
              await ref.read(authRepositoryProvider).acceptTermsOnServer();
              await EulaAcceptanceStore(
                ref.read(preferencesProvider),
              ).acceptForUser(userId);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.text(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: bodyStyle,
          children: <TextSpan>[
            TextSpan(text: l10n.profileEulaBodyBeforeTerms),
            TextSpan(
              text: l10n.authTermsLink,
              style: AppTypography.authTextLinkUnderline(
                textTheme,
              ).copyWith(color: AppColors.primaryDark),
              recognizer: TapGestureRecognizer()
                ..onTap = () => unawaited(_openTerms()),
            ),
            TextSpan(text: l10n.profileEulaBodyAfterTerms),
          ],
        ),
      ),
    );
  }
}
