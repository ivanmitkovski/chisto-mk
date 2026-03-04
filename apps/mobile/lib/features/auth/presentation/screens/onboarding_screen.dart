import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
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
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
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
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.14),
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
                      color: Color(0xFFE9EBF1),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, (systemPadding.bottom + 10).clamp(14, 26)),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          _slides.length,
                          (int index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _activePage == index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _activePage == index ? AppColors.primary : AppColors.divider,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: compact ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        AppAssets.brandLogoGreenBlack,
                        width: compact ? 84 : 90,
                        height: compact ? 24 : 26,
                        fit: BoxFit.contain,
                      ),
                      const Text(
                        ' Chisto.mk',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  title,
                  textAlign: TextAlign.center,
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
                const SizedBox(height: 4),
                Text(
                  supporting,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
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
