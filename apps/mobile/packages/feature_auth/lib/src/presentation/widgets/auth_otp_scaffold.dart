import 'package:chisto_infrastructure/shared/widgets/organisms/auth_screen_header.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared OTP screen chrome for registration and password-reset flows.
class AuthOtpScaffold extends StatelessWidget {
  const AuthOtpScaffold({
    super.key,
    this.leading,
    this.errorBanner,
    this.headerIllustration,
    required this.title,
    required this.subtitle,
    this.headerCentered = false,
    required this.otpInput,
    required this.continueButton,
    required this.resendButton,
    this.footer,
    this.loadingOverlay,
  });

  final Widget? leading;
  final Widget? errorBanner;
  final Widget? headerIllustration;
  final String title;
  final String subtitle;
  final bool headerCentered;
  final Widget otpInput;
  final Widget continueButton;
  final Widget resendButton;
  final Widget? footer;
  final Widget? loadingOverlay;

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Stack(
      children: <Widget>[
        Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColors.panelBackground,
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: AnimatedPadding(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.medium,
                curve: AppMotion.emphasized,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (leading != null) leading!,
                      if (errorBanner != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        errorBanner!,
                        if (headerIllustration == null)
                          const SizedBox(height: AppSpacing.md),
                      ],
                      if (headerIllustration != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxl),
                        Center(child: headerIllustration),
                        const SizedBox(height: AppSpacing.radius22),
                      ],
                      AuthScreenHeader(
                        centered: headerCentered,
                        title: title,
                        subtitle: subtitle,
                        subtitleMaxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.radiusPill),
                      otpInput,
                      const SizedBox(height: AppSpacing.radiusPill),
                      continueButton,
                      const SizedBox(height: AppSpacing.lg),
                      Center(child: resendButton),
                      if (footer != null) footer!,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (loadingOverlay != null) loadingOverlay!,
      ],
    );
  }
}
