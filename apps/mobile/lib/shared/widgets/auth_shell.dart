import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';

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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.panelBackground,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.primary.withValues(alpha: 0.16),
                      AppColors.appBackground,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            topInset > 20 ? 20 : 16,
                            20,
                            24,
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
                                top: Radius.circular(keyboardVisible ? 24 : 36),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, -6),
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