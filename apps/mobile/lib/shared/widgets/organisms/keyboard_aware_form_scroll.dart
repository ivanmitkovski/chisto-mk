import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class KeyboardAwareFormScroll extends StatelessWidget {
  const KeyboardAwareFormScroll({
    super.key,
    required this.child,
    this.padding,
    this.controller,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  /// Extra scroll extent when the parent scaffold keeps [resizeToAvoidBottomInset]
  /// false and the keyboard is shown via [MediaQuery.viewInsets] (see profile
  /// primary action bar). When the scaffold resizes for the keyboard, inset is
  /// usually zero here and this adds nothing.
  static const double _extraPaddingAboveKeyboard = 280;

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final EdgeInsets base = padding is EdgeInsets
        ? padding! as EdgeInsets
        : const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          );
    final double extraBottom = keyboardInset > 0
        ? keyboardInset + _extraPaddingAboveKeyboard
        : 0;
    final EdgeInsetsGeometry resolved = base.add(EdgeInsets.only(bottom: extraBottom));

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        controller: controller,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: resolved,
        child: child,
      ),
    );
  }
}
