import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Dual primary/secondary CTAs for sheet footers with long localized labels.
///
/// Defaults to a vertical stack (secondary above primary). Use [vertical: false]
/// to allow a horizontal layout when [horizontalBreakpoint] is met.
class AppSheetFooterActions extends StatelessWidget {
  const AppSheetFooterActions({
    super.key,
    required this.primary,
    required this.secondary,
    this.vertical = true,
    this.horizontalBreakpoint = 360,
  });

  final Widget primary;
  final Widget secondary;
  final bool vertical;
  final double horizontalBreakpoint;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return _verticalStack();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < horizontalBreakpoint) {
          return _verticalStack();
        }
        return Row(
          children: <Widget>[
            Expanded(child: secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: primary),
          ],
        );
      },
    );
  }

  Widget _verticalStack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        secondary,
        const SizedBox(height: AppSpacing.sm),
        primary,
      ],
    );
  }
}
