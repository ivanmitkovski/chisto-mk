import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _activePage = 0;

  static const List<_SlideData> _slides = <_SlideData>[
    _SlideData(
      title: 'Welcome',
      description: 'See it. Report it. Clean it.',
      supporting: 'A cleaner city starts with one tap.',
    ),
    _SlideData(
      title: 'Report in Seconds',
      description: 'Share a report with location in a few taps.',
      supporting: 'Fast flow, clear status updates.',
    ),
    _SlideData(
      title: 'Join Cleanup Events',
      description: 'Track progress and community impact nearby.',
      supporting: 'Together we keep neighborhoods green.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onContinueTap() {
    HapticFeedback.lightImpact();
    if (_activePage < _slides.length - 1) {
      _pageController.nextPage(
        duration: AppMotion.standard,
        curve: AppMotion.emphasized,
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets systemPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppAssets.peopleCleaning,
                    fit: BoxFit.cover,
                    alignment: const Alignment(-0.20, -0.10),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          AppColors.transparent,
                          AppColors.white.withValues(alpha: 0.14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.panelBackground,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.radiusSm, AppSpacing.lg, (systemPadding.bottom + AppSpacing.radius10).clamp(AppSpacing.radius14, AppSpacing.radius22)),
                  child: Column(
                    children: [
                      Container(
                        width: AppSpacing.sheetHandle,
                        height: AppSpacing.sheetHandleHeight,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radiusSm),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          physics: const BouncingScrollPhysics(),
                          allowImplicitScrolling: true,
                          onPageChanged: (int index) {
                            HapticFeedback.selectionClick();
                            setState(() => _activePage = index);
                          },
                          itemBuilder: (BuildContext context, int index) {
                            final _SlideData slide = _slides[index];
                            return _OnboardingSlide(
                              isWelcome: index == 0,
                              title: slide.title,
                              description: slide.description,
                              supporting: slide.supporting,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          _slides.length,
                          (int index) => AnimatedContainer(
                            duration: AppMotion.medium,
                            curve: AppMotion.emphasized,
                            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                            width: _activePage == index ? AppSpacing.radius18 : AppSpacing.xs,
                            height: AppSpacing.xs,
                            decoration: BoxDecoration(
                              color: _activePage == index ? AppColors.primary : AppColors.divider,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radius14),
                      PrimaryButton(
                        label: _activePage == _slides.length - 1 ? 'Get Started' : 'Continue',
                        onPressed: _onContinueTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.isWelcome,
    required this.title,
    required this.description,
    required this.supporting,
  });

  final bool isWelcome;
  final String title;
  final String description;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 96;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWelcome)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Text(
                        'Welcome to',
                        style: AppTypography.authHeadline.copyWith(
                          fontSize: compact ? 20 : 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.radiusSm),
                      SvgPicture.asset(
                        AppAssets.brandLogoGreenBlack,
                        width: compact ? 84 : 90,
                        height: compact ? 24 : 26,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        ' Chisto.mk',
                        style: AppTypography.authHeadline.copyWith(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.authHeadline.copyWith(
                    fontSize: compact ? 24 : 26,
                  ),
                ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.authSubtitle.copyWith(
                  fontSize: compact ? 14 : 15,
                ),
              ),
              if (!compact) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  supporting,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardSubtitle.copyWith(
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.description,
    required this.supporting,
  });

  final String title;
  final String description;
  final String supporting;
}
