import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  final VoidCallback? onPressed;
  final Color? backgroundColor;
  /// When null, uses [AppColors.textPrimary] (light surfaces).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final String backLabel = AppLocalizations.of(context)?.authSemanticGoBack ??
        MaterialLocalizations.of(context).backButtonTooltip;
    return Semantics(
      label: backLabel,
      button: true,
      child: Material(
        color: AppColors.transparent,
        child: CircleAvatar(
          radius: AppSpacing.iconMd,
          backgroundColor: backgroundColor ?? AppColors.appBackground,
          child: IconButton(
            tooltip: backLabel,
            iconSize: AppSpacing.iconSm,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
            onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
            icon: SvgPicture.asset(
              AppAssets.arrowLeft,
              width: AppSpacing.iconSm,
              height: AppSpacing.iconSm,
              colorFilter: ColorFilter.mode(
                iconColor ?? AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
