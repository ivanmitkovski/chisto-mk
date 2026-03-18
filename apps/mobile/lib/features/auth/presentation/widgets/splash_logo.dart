import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/splash_constants.dart';

/// Splash logo: Lottie animation with static SVG fallback on load error.
///
/// [width] and [height] are optional; when provided (e.g. from screen size),
/// the logo is responsive. Otherwise uses [SplashConstants] fallbacks.
/// Controller is not started here; caller starts it in Lottie's onLoaded.
class SplashLogo extends StatelessWidget {
  const SplashLogo({
    super.key,
    required this.controller,
    this.width,
    this.height,
  });

  final AnimationController controller;
  final double? width;
  final double? height;

  double get _width => width ?? SplashConstants.logoWidth;
  double get _height => height ?? SplashConstants.logoHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Chisto logo',
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: _width, height: _height),
        child: ClipRect(
          child: SizedBox(
            width: _width,
            height: _height,
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: SplashConstants.lottieInnerWidth,
                height: SplashConstants.lottieInnerHeight,
                child: RepaintBoundary(
                  child: Lottie.asset(
                    AppAssets.splashLogoLottie,
                    controller: controller,
                    fit: BoxFit.fill,
                    alignment: Alignment.center,
                    repeat: false,
                    onLoaded: (LottieComposition composition) {
                      controller.duration = composition.duration;
                      controller.forward();
                    },
                    errorBuilder: (_, Object error, StackTrace? stackTrace) =>
                        const _FallbackLogo(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static logo shown when Lottie fails to load. Uses same inner size and fill
/// as Lottie so scaling is identical (no size jump).
class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.brandGlyphWhite,
      width: SplashConstants.lottieInnerWidth,
      height: SplashConstants.lottieInnerHeight,
      fit: BoxFit.fill,
    );
  }
}
