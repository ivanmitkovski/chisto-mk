import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.backgroundColor});

  final VoidCallback? onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: CircleAvatar(
        radius: AppSpacing.iconMd,
        backgroundColor: backgroundColor ?? AppColors.appBackground,
        child: IconButton(
          iconSize: AppSpacing.iconSm,
          onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
          icon: SvgPicture.asset(
            AppAssets.arrowLeft,
            width: AppSpacing.iconSm,
            height: AppSpacing.iconSm,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
