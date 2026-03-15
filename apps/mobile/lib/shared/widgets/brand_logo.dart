import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

enum BrandLogoVariant { light, dark }

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.light,
    this.logoHeight,
    this.compact = false,
  });

  final BrandLogoVariant variant;
  final double? logoHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isDark = variant == BrandLogoVariant.dark;
    final double height = logoHeight ?? (compact ? 28 : 32);
    final String logoSvg = isDark ? AppAssets.brandGlyphWhite : AppAssets.brandLogoGreenBlack;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: height,
        child: SvgPicture.asset(
          logoSvg,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
