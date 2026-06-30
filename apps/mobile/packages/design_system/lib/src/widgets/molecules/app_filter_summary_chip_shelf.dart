import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Fixed-height shelf for active filter chips so toggling filters does not
/// shift the sheet layout.
class AppFilterSummaryChipShelf extends StatelessWidget {
  const AppFilterSummaryChipShelf({super.key, required this.chips});

  final List<Widget> chips;

  static const double shelfHeight = 44;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: shelfHeight,
      child: chips.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: chips.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) => chips[index],
            ),
    );
  }
}
