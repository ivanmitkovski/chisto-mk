import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Section label + optional trailing actions for filter bottom sheets.
class AppFilterSheetSection extends StatelessWidget {
  const AppFilterSheetSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.sectionKey,
    this.contentPadding,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Key? sectionKey;

  /// Padding around [child]. Defaults to horizontal [AppSpacing.lg].
  ///
  /// Use [EdgeInsets.zero] when the parent sheet already applies horizontal
  /// inset so grouped lists can stretch edge-to-edge with the section title.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return KeyedSubtree(
      key: sectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.eventsSheetSectionLabel(textTheme),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}
