import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/widgets/molecules/app_grouped_action_list.dart';
import 'package:design_system/src/widgets/molecules/app_selection_instruction.dart';
import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_bottom_sheet.dart';
import 'package:design_system/src/widgets/organisms/app_surface/app_surface_primitives.dart';
import 'package:flutter/cupertino.dart';

/// One row in a grouped option picker sheet.
class AppGroupedOption<T> {
  const AppGroupedOption({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.semanticsLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final T value;
  final String? semanticsLabel;
}

/// Inset-grouped option list inside [AppSheetScaffold] chrome.
///
/// Use [showAppGroupedOptionPicker] for the full modal, or embed this body in
/// a custom host (e.g. [AppBottomSheet.show] with a footer).
class AppGroupedOptionPickerSheet<T> extends StatelessWidget {
  const AppGroupedOptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.isSelected,
    required this.onOptionTap,
    this.subtitle,
    this.instructionMessage,
    this.footer,
    this.trailingBuilder,
    this.maxHeightFactor = 0.82,
    this.closeSemanticLabel,
  });

  final String title;
  final String? subtitle;
  final List<AppGroupedOption<T>> options;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onOptionTap;
  final String? instructionMessage;
  final Widget? footer;
  final Widget Function(T value, {required bool isActive})? trailingBuilder;
  final double maxHeightFactor;
  final String? closeSemanticLabel;

  static Widget defaultTrailing({required bool isActive}) {
    return Icon(
      isActive ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
      size: 22,
      color: isActive ? AppColors.primaryDark : AppColors.divider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: title,
      subtitle: subtitle,
      trailing: AppCircleIconButton(
        icon: CupertinoIcons.xmark,
        semanticLabel: closeSemanticLabel ?? 'Close',
        onTap: () => Navigator.of(context).pop(),
      ),
      maxHeightFactor: maxHeightFactor,
      fitToContent: true,
      useModalRouteShape: true,
      addBottomInset: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      footer: footer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (instructionMessage != null)
            AppSelectionInstruction(message: instructionMessage!),
          AppGroupedActionList(
            children: options
                .map((AppGroupedOption<T> option) {
                  final bool active = isSelected(option.value);
                  final Widget trailing =
                      trailingBuilder?.call(option.value, isActive: active) ??
                      defaultTrailing(isActive: active);
                  return Semantics(
                    button: true,
                    selected: active,
                    label: option.semanticsLabel ?? option.title,
                    child: AppActionTile(
                      variant: AppActionTileVariant.grouped,
                      icon: option.icon,
                      title: option.title,
                      subtitle: option.subtitle,
                      tone: active
                          ? AppSurfaceTone.accent
                          : AppSurfaceTone.neutral,
                      trailing: trailing,
                      onTap: () => onOptionTap(option.value),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

/// Shows a scroll-controlled grouped option picker via [AppBottomSheet.show].
Future<void> showAppGroupedOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<AppGroupedOption<T>> options,
  required bool Function(T value) isSelected,
  required ValueChanged<T> onOptionTap,
  String? subtitle,
  String? instructionMessage,
  Widget? footer,
  Widget Function(T value, {required bool isActive})? trailingBuilder,
  double maxHeightFactor = 0.82,
  String? closeSemanticLabel,
  bool popOnSelect = true,
}) {
  return AppBottomSheet.show<void>(
    context: context,
    maxHeightFactor: maxHeightFactor,
    builder: (BuildContext ctx) {
      return AppGroupedOptionPickerSheet<T>(
        title: title,
        subtitle: subtitle,
        options: options,
        isSelected: isSelected,
        onOptionTap: (T value) {
          onOptionTap(value);
          if (popOnSelect) {
            Navigator.of(ctx).pop();
          }
        },
        instructionMessage: instructionMessage,
        footer: footer,
        trailingBuilder: trailingBuilder,
        maxHeightFactor: maxHeightFactor,
        closeSemanticLabel: closeSemanticLabel,
      );
    },
  );
}
