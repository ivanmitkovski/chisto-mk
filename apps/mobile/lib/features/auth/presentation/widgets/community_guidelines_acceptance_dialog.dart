import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/auth/data/eula_acceptance_store.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_modal_dialog.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';

/// Blocking community-guidelines acceptance (App Store UGC 1.2).
///
/// Returns `true` if the user accepted and persistence succeeded.
Future<bool> showCommunityGuidelinesAcceptanceDialog(
  BuildContext context, {
  required String userId,
}) async {
  final bool? accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.black.withValues(alpha: 0.45),
    builder: (BuildContext ctx) => _CommunityGuidelinesAcceptanceDialog(
      termsUrl: AppBootstrap.instance.config.termsUrl,
      userId: userId,
    ),
  );
  return accepted == true;
}

class _CommunityGuidelinesAcceptanceDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              await EulaAcceptanceStore(AppBootstrap.instance.preferences)
                  .acceptForUser(userId);
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
              style: AppTypography.authTextLinkUnderline.copyWith(
                color: AppColors.primaryDark,
              ),
              recognizer: TapGestureRecognizer()..onTap = () => unawaited(_openTerms()),
            ),
            TextSpan(text: l10n.profileEulaBodyAfterTerms),
          ],
        ),
      ),
    );
  }
}
