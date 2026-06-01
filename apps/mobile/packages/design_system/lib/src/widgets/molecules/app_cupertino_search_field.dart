import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Cupertino-style search field shared by reports list, events feed, and similar surfaces.
///
/// Matches iOS search affordance: [CupertinoSearchTextField], tap-outside unfocus, and
/// [AppColors.inputFill] treatment used on reports.
class AppCupertinoSearchField extends StatelessWidget {
  const AppCupertinoSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.semanticLabel,
    required this.onSubmitted,
    required this.onClear,
    this.semanticHint,
    this.onChanged,
    this.autocorrect = true,
    this.smartQuotesType,
    this.smartDashesType,
    this.enableIMEPersonalizedLearning = true,
    this.toolbarHeight,
    this.textStyle,
    this.placeholderStyle,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;
  final bool autocorrect;
  final SmartQuotesType? smartQuotesType;
  final SmartDashesType? smartDashesType;
  final bool enableIMEPersonalizedLearning;

  /// Fixed outer height so the bar lines up with square toolbar controls (e.g. events feed).
  final double? toolbarHeight;

  /// When set, overrides the default body-medium search text style.
  final TextStyle? textStyle;

  /// When set, overrides the default muted placeholder style.
  final TextStyle? placeholderStyle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle resolvedTextStyle =
        textStyle ?? AppTypography.eventsSearchFieldText(textTheme);
    final TextStyle resolvedPlaceholderStyle =
        placeholderStyle ??
        AppTypography.eventsSearchFieldPlaceholder(textTheme);

    final EdgeInsetsGeometry fieldPadding = toolbarHeight != null
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.radius10,
          );

    final Widget field = CupertinoSearchTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      style: resolvedTextStyle,
      placeholderStyle: resolvedPlaceholderStyle,
      padding: fieldPadding,
      backgroundColor: AppColors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      onSuffixTap: onClear,
      autocorrect: autocorrect,
      smartQuotesType: smartQuotesType,
      smartDashesType: smartDashesType,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
    );

    final Widget body = toolbarHeight != null
        ? SizedBox(
            height: toolbarHeight,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(child: field),
            ),
          )
        : SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: field,
            ),
          );

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      textField: true,
      child: TapRegion(
        onTapOutside: (PointerDownEvent _) {
          focusNode.unfocus();
        },
        child: body,
      ),
    );
  }
}
