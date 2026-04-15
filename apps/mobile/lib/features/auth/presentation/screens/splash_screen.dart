import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/splash_constants.dart';
import 'package:chisto_mobile/features/auth/presentation/widgets/splash_logo.dart';

/// Splash: Lottie until [SplashConstants.lottieProgressCutoff], then fade to
/// initial route (no static logo swap, so Lottie size stays consistent).
/// Session restore starts during splash for a snappier feel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )
      ..addStatusListener(_onLottieStatus)
      ..addListener(_onLottieProgress);

    unawaited(_restoreSessionDuringSplash());
    _precacheAssets();
    _startMaxDurationFallback();
  }

  Future<void> _restoreSessionDuringSplash() async {
    try {
      await ServiceLocator.instance.authRepository.restoreSession();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Splash] session restore failed: $error');
        debugPrint('$stackTrace');
      } else {
        debugPrint('[Splash] session restore failed (${error.runtimeType})');
      }
    }
  }

  void _precacheAssets() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage(AppAssets.peopleCleaning), context);
    });
  }

  void _startMaxDurationFallback() {
    Future<void>.delayed(SplashConstants.splashMaxDuration, () {
      if (!_navigating && mounted) _scheduleNavigate();
    });
  }

  @override
  void dispose() {
    _lottieController.removeStatusListener(_onLottieStatus);
    _lottieController.removeListener(_onLottieProgress);
    _lottieController.dispose();
    super.dispose();
  }

  void _onLottieStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _navigating) return;
    _scheduleNavigate();
  }

  void _onLottieProgress() {
    if (_navigating || !mounted) return;
    if (_lottieController.value >= SplashConstants.lottieProgressCutoff) {
      _scheduleNavigate();
    }
  }

  /// Keep Lottie on screen until we replace with initial route (no static swap).
  void _scheduleNavigate() {
    if (_navigating) return;
    _navigating = true;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.initialRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double logoWidth = (screenWidth * SplashConstants.logoFractionOfScreenWidth)
        .clamp(SplashConstants.logoMinWidth, SplashConstants.logoMaxWidth);
    final double logoHeight = logoWidth * SplashConstants.logoAspectRatio;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SplashLogo(
            controller: _lottieController,
            width: logoWidth,
            height: logoHeight,
          ),
        ),
      ),
    );
  }
}
