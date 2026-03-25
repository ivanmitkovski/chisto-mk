import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/shared/widgets/app_pill_filter_chips.dart';

export 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';

class EventsFilterChips extends StatelessWidget {
  const EventsFilterChips({
    super.key,
    required this.active,
    required this.onSelected,
  });

  final EcoEventFilter active;
  final ValueChanged<EcoEventFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppPillFilterChips(
      labels: EcoEventFilter.values.map((EcoEventFilter f) => f.label).toList(),
      selectedIndex: EcoEventFilter.values.indexOf(active),
      semanticLabelPrefix: 'Events',
      onSelected: (int index) => onSelected(EcoEventFilter.values[index]),
    );
  }
}
