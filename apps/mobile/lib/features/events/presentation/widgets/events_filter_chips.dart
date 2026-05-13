import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/shared/widgets/app_filter_pill_bar.dart';

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
    String labelFor(EcoEventFilter filter) {
      switch (filter) {
        case EcoEventFilter.all:
          return context.l10n.eventsFilterAll;
        case EcoEventFilter.upcoming:
          return context.l10n.eventsFilterUpcoming;
        case EcoEventFilter.nearby:
          return context.l10n.eventsFilterNearby;
        case EcoEventFilter.past:
          return context.l10n.eventsFilterPast;
        case EcoEventFilter.myEvents:
          return context.l10n.eventsFilterMyEvents;
      }
    }

    return AppFilterPillBar<EcoEventFilter>(
      variant: AppFilterPillVariant.feedChip,
      items: <FilterPillItem<EcoEventFilter>>[
        for (final EcoEventFilter f in EcoEventFilter.values)
          FilterPillItem<EcoEventFilter>(
            value: f,
            label: labelFor(f),
            semanticsLabel: context.l10n.feedFilterSemantic(labelFor(f)),
          ),
      ],
      selected: active,
      onSelected: onSelected,
    );
  }
}
