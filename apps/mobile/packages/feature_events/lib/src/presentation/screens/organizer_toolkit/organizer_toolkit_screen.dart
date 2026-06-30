import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/presentation/navigation/organizer_certification_navigation.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_quiz_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizerToolkitScreen extends ConsumerStatefulWidget {
  const OrganizerToolkitScreen({super.key, this.onProceedToCreate});

  final OrganizerCertificationProceedHandler? onProceedToCreate;

  @override
  ConsumerState<OrganizerToolkitScreen> createState() =>
      _OrganizerToolkitScreenState();
}

class _OrganizerToolkitScreenState
    extends ConsumerState<OrganizerToolkitScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _authListenerAttached = false;
  bool _quizRouteOpen = false;
  late final AuthState _authState;

  static const int _totalPages = 8;

  void _detachAuthListener() {
    if (!_authListenerAttached) {
      return;
    }
    _authListenerAttached = false;
    _authState.removeListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (!mounted) {
      return;
    }
    _exitToolkitIfAlreadyCertified();
  }

  /// [AuthState] can gain certification after `/auth/me` while this route is open.
  void _exitToolkitIfAlreadyCertified() {
    if (!mounted) {
      return;
    }
    if (!ref.read(authStateProvider).isOrganizerCertified) {
      return;
    }
    // Quiz dismissal + create-event handoff is handled on the result screen.
    if (_quizRouteOpen) {
      return;
    }
    _detachAuthListener();
    widget.onProceedToCreate?.call();
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _authState = ref.read(authStateProvider);
    _authState.addListener(_onAuthStateChanged);
    _authListenerAttached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _exitToolkitIfAlreadyCertified();
    });
  }

  @override
  void dispose() {
    _detachAuthListener();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Duration duration = reduceMotion
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 350);
    final Curve curve = reduceMotion ? Curves.linear : Curves.easeInOut;

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: duration, curve: curve);
    } else {
      setState(() => _quizRouteOpen = true);
      unawaited(
        Navigator.of(context)
            .push<void>(
              MaterialPageRoute<void>(
                settings: const RouteSettings(
                  name: organizerCertificationQuizRouteName,
                ),
                builder: (_) => OrganizerQuizScreen(
                  onProceedToCreate: widget.onProceedToCreate,
                ),
              ),
            )
            .whenComplete(() {
              if (mounted) {
                setState(() => _quizRouteOpen = false);
              }
            }),
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
                    const AppBackButton(backgroundColor: AppColors.inputFill),
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
                onPageChanged: (int page) =>
                    setState(() => _currentPage = page),
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: AppRadii.xs,
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
                    child: Icon(
                      data.icon,
                      size: 40,
                      color: AppColors.primaryDark,
                    ),
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
