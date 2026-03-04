import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Warm up the large onboarding hero image to avoid first-swipe lag.
      precacheImage(const AssetImage(AppAssets.peopleCleaning), context);
    });
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SvgPicture.asset(
            AppAssets.brandGlyphWhite,
            width: 120,
            height: 138,
          ),
        ),
      ),
    );
  }
}
