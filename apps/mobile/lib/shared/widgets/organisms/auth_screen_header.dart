import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/brand_logo.dart';

/// Shared title + subtitle block for [AuthShell] and other auth flows.
///
/// Matches sign-in typography so login, register, and password-reset screens
/// stay visually aligned.
class AuthScreenHeader extends StatelessWidget {
  const AuthScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = false,
    this.showBackButton = false,
    this.centered = false,
    this.subtitleMaxLines,
  }) : assert(
         !showLogo || !showBackButton,
         'Use either showLogo or showBackButton, not both',
       );

  final String title;
  final String? subtitle;
  final bool showLogo;
  final bool showBackButton;
  final bool centered;
  final int? subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final TextAlign textAlign =
        centered ? TextAlign.center : TextAlign.start;
    final CrossAxisAlignment crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        if (showBackButton) ...<Widget>[
          const AppBackButton(),
          const SizedBox(height: AppSpacing.md),
        ],
        if (showLogo) ...<Widget>[
          const BrandLogo(compact: true),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: AppTypography.authScreenTitle(context),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: textAlign,
            maxLines: subtitleMaxLines,
            overflow:
                subtitleMaxLines != null ? TextOverflow.ellipsis : null,
            style: AppTypography.authScreenSubtitle(context),
          ),
        ],
      ],
    );
  }
}
