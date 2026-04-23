import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_location_detail_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/category_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/date_time_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_details_grid.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/location_chip.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Event “where / when / what” block: separate soft cards and a chip strip instead of one grouped table.
class EventDetailFactsSection extends StatelessWidget {
  const EventDetailFactsSection({
    super.key,
    required this.event,
    required this.onExportCalendar,
  });

  final EcoEvent event;
  final VoidCallback onExportCalendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DateTimeSection(
          event: event,
          onExportCalendar: onExportCalendar,
          embeddedInGroupedPanel: false,
        ),
        const SizedBox(height: AppSpacing.md),
        _LocationFactCard(event: event),
        const SizedBox(height: AppSpacing.md),
        _EventMetaChipsStrip(event: event),
      ],
    );
  }
}

class _LocationFactCard extends StatelessWidget {
  const _LocationFactCard({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasCoords = event.siteLat != null && event.siteLng != null;

    return Semantics(
      button: true,
      label: event.siteName,
      hint: context.l10n.eventsDetailLocationLongPressHint,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => LocationChip.openSiteDetail(context, event),
          onLongPress: () {
            AppHaptics.light();
            unawaited(showEventLocationDetailSheet(context, event: event));
          },
          borderRadius: EventDetailSurfaceDecoration.cardBorderRadius,
          child: DecoratedBox(
            decoration: EventDetailSurfaceDecoration.detailModule(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      CupertinoIcons.location_solid,
                      size: 22,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.l10n.eventsDetailLocationTitle,
                          style: AppTypography.eventsCaptionStrong(
                            textTheme,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          event.siteName,
                          style: AppTypography.eventsGroupedRowPrimary(textTheme),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hasCoords)
                    IconButton(
                      tooltip: context.l10n.eventsDetailOpenInMaps,
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.avatarMd,
                        minHeight: AppSpacing.avatarMd,
                      ),
                      onPressed: () => LocationChip.openMapsSheet(context, event),
                      icon: const Icon(
                        CupertinoIcons.map_fill,
                        size: AppSpacing.iconMd,
                        color: AppColors.primaryDark,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventMetaChipsStrip extends StatelessWidget {
  const _EventMetaChipsStrip({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return DecoratedBox(
      decoration: EventDetailSurfaceDecoration.detailModule(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            DetailChip(
              icon: event.category.icon,
              label: event.category.localizedLabel(l10n),
              color: AppColors.primaryDark,
              onTap: () => CategorySection.showCategoryInfoSheet(context, event),
            ),
            if (event.scale != null)
              DetailChip(
                icon: Icons.groups_rounded,
                label: event.scale!.localizedLabel(l10n),
                color: AppColors.primaryDark,
                onTap: () => EventDetailsGrid.openScaleInfoSheet(context, event),
              ),
            if (event.difficulty != null)
              DetailChip(
                icon: CupertinoIcons.shield_fill,
                label: event.difficulty!.localizedLabel(l10n),
                color: event.difficulty!.color,
                onTap: () =>
                    EventDetailsGrid.openDifficultyInfoSheet(context, event),
              ),
          ],
        ),
      ),
    );
  }
}
