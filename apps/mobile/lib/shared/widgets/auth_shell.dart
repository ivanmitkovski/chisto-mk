import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.header,
    required this.body,
  });

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double topInset = MediaQuery.paddingOf(context).top;
    final bool keyboardVisible = keyboardInset > 0;
    final Size screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.panelBackground,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const <double>[0.0, 0.28, 0.5, 1.0],
                    colors: <Color>[
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0.14),
                      AppColors.primary.withValues(alpha: 0.06),
                      AppColors.appBackground,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -screenSize.height * 0.06,
              right: -screenSize.width * 0.18,
              child: Opacity(
                opacity: 0.08,
                child: SvgPicture.asset(
                  AppAssets.brandLogoGreen,
                  width: screenSize.width * 1.12,
                  height: screenSize.width * 1.3,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomLeft,
                ),
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.42,
              left: -screenSize.width * 0.3,
              child: Opacity(
                opacity: 0.045,
                child: SvgPicture.asset(
                  AppAssets.brandLogoGreen,
                  width: screenSize.width * 0.9,
                  height: screenSize.width * 1.04,
                  fit: BoxFit.contain,
                  alignment: Alignment.topRight,
                ),
              ),
            ),
            SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.radiusXl,
                            topInset > AppSpacing.radiusXl
                                ? AppSpacing.radiusXl
                                : AppSpacing.md,
                            AppSpacing.radiusXl,
                            AppSpacing.lg,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: double.infinity,
                              child: header,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(
                                  keyboardVisible
                                      ? AppSpacing.radiusCard
                                      : AppSpacing.radiusSheet,
                                ),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: keyboardVisible
                                      ? 32
                                      : AppSpacing.radiusXl,
                                  offset: Offset(
                                    0,
                                    keyboardVisible ? -2 : -AppSpacing.xs,
                                  ),
                                ),
                              ],
                            ),
                            child: body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
