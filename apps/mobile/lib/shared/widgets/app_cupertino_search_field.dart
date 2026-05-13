import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

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
      style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      placeholderStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textMuted,
      ),
      padding: fieldPadding,
      backgroundColor:
          toolbarHeight != null ? Colors.transparent : AppColors.inputFill,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      onSuffixTap: () {
        AppHaptics.tap();
        onClear();
      },
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
              child: Center(
                child: field,
              ),
            ),
          )
        : field;

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
