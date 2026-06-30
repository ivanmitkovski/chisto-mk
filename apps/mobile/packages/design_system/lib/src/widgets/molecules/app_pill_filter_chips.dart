import 'package:design_system/src/widgets/molecules/app_filter_pill_bar.dart';
import 'package:flutter/material.dart';

/// Back-compat wrapper over [AppFilterPillBar] indexed by position.
///
/// Prefer [AppFilterPillBar] with typed values for new UI.
class AppPillFilterChips extends StatelessWidget {
  const AppPillFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabelPrefix = 'Filter',
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String semanticLabelPrefix;

  @override
  Widget build(BuildContext context) {
    return AppFilterPillBar<int>(
      variant: AppFilterPillVariant.feedChip,
      items: <FilterPillItem<int>>[
        for (int i = 0; i < labels.length; i++)
          FilterPillItem<int>(
            value: i,
            label: labels[i],
            semanticsLabel: '$semanticLabelPrefix ${labels[i]}',
          ),
      ],
      selected: selectedIndex,
      onSelected: onSelected,
    );
  }
}
