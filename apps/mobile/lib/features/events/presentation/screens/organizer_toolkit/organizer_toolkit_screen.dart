import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/presentation/screens/organizer_toolkit/organizer_quiz_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class OrganizerToolkitScreen extends StatefulWidget {
  const OrganizerToolkitScreen({super.key, this.onCertified});

  final VoidCallback? onCertified;

  @override
  State<OrganizerToolkitScreen> createState() => _OrganizerToolkitScreenState();
}

class _OrganizerToolkitScreenState extends State<OrganizerToolkitScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 8;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    AppHaptics.tap();
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Duration duration = reduceMotion
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 350);
    final Curve curve = reduceMotion ? Curves.linear : Curves.easeInOut;

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: duration,
        curve: curve,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrganizerQuizScreen(onCertified: widget.onCertified),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final List<_TutorialPageData> pages = <_TutorialPageData>[
      _TutorialPageData(
        icon: CupertinoIcons.shield_lefthalf_fill,
        title: context.l10n.organizerToolkitPage1Title,
        body: context.l10n.organizerToolkitPage1Body,
      ),
      _TutorialPageData(
        icon: CupertinoIcons.checkmark_seal_fill,
        title: context.l10n.organizerToolkitPage2Title,
        body: context.l10n.organizerToolkitPage2Body,
      ),
      _TutorialPageData(
        icon: CupertinoIcons.qrcode_viewfinder,
        title: context.l10n.organizerToolkitPage3Title,
        body: context.l10n.organizerToolkitPage3Body,
      ),
      _TutorialPageData(
        icon: CupertinoIcons.cloud_sun_fill,
        title: context.l10n.organizerToolkitPage4Title,
        body: context.l10n.organizerToolkitPage4Body,
      ),
      _TutorialPageData(
        icon: CupertinoIcons.trash_fill,
        title: context.l10n.organizerToolkitPage5Title,
        body: context.l10n.organizerToolkitPage5Body,
      ),
      _TutorialPageData(
        icon: CupertinoIcons.person_3_fill,
        title: context.l10n.organizerToolkitPage6Title,
        body: context.l10n.organizerToolkitPage6Body,
      ),
      _TutorialPageData(
        icon: CupertinoIcons.lock_fill,
        title: context.l10n.organizerToolkitPage7Title,
        body: context.l10n.organizerToolkitPage7Body,
      ),
      _TutorialPageData(
        icon: CupertinoIcons.photo_fill_on_rectangle_fill,
        title: context.l10n.organizerToolkitPage8Title,
        body: context.l10n.organizerToolkitPage8Body,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Semantics(
                header: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    AppBackButton(backgroundColor: AppColors.inputFill),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        context.l10n.organizerToolkitTitle,
                        style: AppTypography.eventsScreenTitle(textTheme),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemBuilder: (BuildContext context, int index) {
                  final _TutorialPageData page = pages[index];
                  return _TutorialPage(data: page);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_totalPages, (int i) {
                  return AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                height: 72,
                child: Center(
                  child: PrimaryButton(
                    label: _currentPage == _totalPages - 1
                        ? context.l10n.organizerToolkitStartQuiz
                        : context.l10n.organizerToolkitContinue,
                    onPressed: _nextPage,
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

class _TutorialPageData {
  const _TutorialPageData({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.data});

  final _TutorialPageData data;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(data.icon, size: 40, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    data.title,
                    style: AppTypography.eventsDetailHeadline(textTheme),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    data.body,
                    style: AppTypography.eventsBodyMuted(textTheme),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
