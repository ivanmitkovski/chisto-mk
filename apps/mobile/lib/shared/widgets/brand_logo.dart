import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 32,
        child: SvgPicture.asset(
          AppAssets.brandLogoGreenBlack,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}