import 'dart:async';

import 'package:chisto_infrastructure/core/assets/app_assets.dart';
import 'package:chisto_infrastructure/core/l10n/app_language_picker.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _activePage = 0;

  List<_SlideData> _slides(AppLocalizations l10n) => <_SlideData>[
    _SlideData(
      title: '',
      description: l10n.authOnboardingWelcomeDescription,
      supporting: l10n.authOnboardingWelcomeSupporting,
      isWelcome: true,
    ),
    _SlideData(
      title: l10n.authOnboardingSlide2Title,
      description: l10n.authOnboardingSlide2Description,
      supporting: l10n.authOnboardingSlide2Supporting,
      isWelcome: false,
    ),
    _SlideData(
      title: l10n.authOnboardingSlide3Title,
      description: l10n.authOnboardingSlide3Description,
      supporting: l10n.authOnboardingSlide3Supporting,
      isWelcome: false,
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

  void _onContinueTap(AppLocalizations l10n) {
    final List<_SlideData> slides = _slides(l10n);
    if (_activePage < slides.length - 1) {
      _pageController.nextPage(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.standard,
        curve: AppMotion.emphasized,
      );
      return;
    }

    unawaited(
      ref.read(onboardingControllerProvider.notifier).completeOnboarding(),
    );
    AppNavigation.goSignIn();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLocaleOverrideProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<_SlideData> slides = _slides(l10n);
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
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          right: AppSpacing.md,
                        ),
                        child: Material(
                          color: AppColors.black.withValues(alpha: 0.18),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            icon: const Icon(Icons.language_rounded),
                            iconSize: 20,
                            color: AppColors.white.withValues(alpha: 0.82),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              minimumSize: const Size(44, 44),
                              tapTargetSize: MaterialTapTargetSize.padded,
                              overlayColor: AppColors.white.withValues(
                                alpha: 0.12,
                              ),
                            ),
                            tooltip: l10n.profileLanguageTile,
                            onPressed: () {
                              showAppLanguagePicker(context);
                            },
                          ),
                        ),
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
                    top: BorderSide(color: AppColors.divider, width: 1),
                  ),
                ),
                child: Padding(
                  // Add the FULL bottom system inset so the CTA always clears the
                  // Android gesture/3-button navigation bar and the iOS home
                  // indicator. `radius14` is the visual gap above that inset (and
                  // the resting padding on devices with no inset). The inset must
                  // never be clamped — a 3-button nav bar is ~48dp, far larger than
                  // any fixed cap — or the button gets covered.
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.radiusSm,
                    AppSpacing.lg,
                    systemPadding.bottom + AppSpacing.radius14,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: AppSpacing.sheetHandle,
                        height: AppSpacing.sheetHandleHeight,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusCircle,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radiusSm),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: slides.length,
                          physics: const BouncingScrollPhysics(),
                          allowImplicitScrolling: true,
                          onPageChanged: (int index) {
                            setState(() => _activePage = index);
                          },
                          itemBuilder: (BuildContext context, int index) {
                            final _SlideData slide = slides[index];
                            return _OnboardingSlide(l10n: l10n, slide: slide);
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          slides.length,
                          (int index) => AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : AppMotion.medium,
                            curve: AppMotion.emphasized,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxs,
                            ),
                            width: _activePage == index
                                ? AppSpacing.radius18
                                : AppSpacing.xs,
                            height: AppSpacing.xs,
                            decoration: BoxDecoration(
                              color: _activePage == index
                                  ? AppColors.primary
                                  : AppColors.divider,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusCircle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.radius14),
                      Semantics(
                        button: true,
                        label: _activePage == slides.length - 1
                            ? l10n.authOnboardingGetStarted
                            : l10n.authOnboardingContinue,
                        child: AppButton.primary(
                          label: _activePage == slides.length - 1
                              ? l10n.authOnboardingGetStarted
                              : l10n.authOnboardingContinue,
                          onPressed: () => _onContinueTap(l10n),
                        ),
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
  const _OnboardingSlide({required this.l10n, required this.slide});

  final AppLocalizations l10n;
  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 96;
        final double contentWidth = (constraints.maxWidth - AppSpacing.xxs * 2)
            .clamp(0.0, double.infinity);
        // Safety net for very short panels (small device + 3-button nav bar +
        // large text scale): scale the copy down to fit instead of overflowing.
        // `scaleDown` is a no-op whenever the content already fits, so taller
        // devices render identically.
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (slide.isWelcome)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            l10n.authOnboardingWelcomeTo,
                            style: AppTypography.authHeadline(
                              textTheme,
                            ).copyWith(fontSize: compact ? 20 : 22),
                          ),
                          const SizedBox(width: AppSpacing.radiusSm),
                          SvgPicture.asset(
                            AppAssets.brandLogoGreen,
                            width: compact ? 84 : 90,
                            height: compact ? 24 : 26,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            ' ${l10n.authOnboardingBrandName}',
                            style: AppTypography.authHeadline(
                              textTheme,
                            ).copyWith(fontSize: 20),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.authHeadline(
                        textTheme,
                      ).copyWith(fontSize: compact ? 24 : 26),
                    ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    slide.description,
                    textAlign: TextAlign.center,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.authSubtitle(
                      textTheme,
                    ).copyWith(fontSize: compact ? 14 : 15),
                  ),
                  if (!compact) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      slide.supporting,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardSubtitle(
                        textTheme,
                      ).copyWith(height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
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
    required this.isWelcome,
  });

  final String title;
  final String description;
  final String supporting;
  final bool isWelcome;
}
