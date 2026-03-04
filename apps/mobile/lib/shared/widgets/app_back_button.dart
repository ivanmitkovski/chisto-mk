import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 19,
      backgroundColor: AppColors.appBackground,
      child: IconButton(
        iconSize: 16,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: SvgPicture.asset(
          AppAssets.arrowLeft,
          width: 16,
          height: 16,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
