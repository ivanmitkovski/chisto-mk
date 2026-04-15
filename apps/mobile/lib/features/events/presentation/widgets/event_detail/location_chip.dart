import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_location_detail_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_site_maps.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class LocationChip extends StatelessWidget {
  const LocationChip({
    super.key,
    required this.event,
    this.embeddedInGroupedPanel = false,
  });

  final EcoEvent event;

  /// When true, renders as an inset row without an outer card (use inside [EventDetailGroupedPanel]).
  final bool embeddedInGroupedPanel;

  void _openSite(BuildContext context) {
    AppHaptics.softTransition();
    final PollutionSite site = EventSiteResolver.resolveSiteForEvent(
      event,
      statusLabel: event.status.localizedLabel(context.l10n),
    );
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => PollutionSiteDetailScreen(site: site),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final double? lat = event.siteLat;
    final double? lng = event.siteLng;
    if (lat == null || lng == null) {
      return;
    }
    AppHaptics.tap();
    await showEventSiteMapsSheet(context, lat: lat, lng: lng);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasCoords = event.siteLat != null && event.siteLng != null;

    return Material(
      color: AppColors.transparent,
      child: embeddedInGroupedPanel
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          '${event.siteName}, ${context.l10n.eventsLocationDotKm(event.siteDistanceKm.toStringAsFixed(1))}',
                      hint: context.l10n.eventsDetailLocationLongPressHint,
                      child: InkWell(
                        onTap: () => _openSite(context),
                        onLongPress: () {
                          AppHaptics.light();
                          unawaited(
                            showEventLocationDetailSheet(context, event: event),
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              CupertinoIcons.location,
                              size: AppSpacing.iconMd,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    event.siteName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    context.l10n.eventsLocationDotKm(
                                      event.siteDistanceKm.toStringAsFixed(1),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasCoords)
                    Semantics(
                      button: true,
                      label: context.l10n.eventsDetailOpenInMaps,
                      child: IconButton(
                        tooltip: context.l10n.eventsDetailOpenInMaps,
                        constraints: const BoxConstraints(
                          minWidth: AppSpacing.avatarMd,
                          minHeight: AppSpacing.avatarMd,
                        ),
                        onPressed: () => _openMaps(context),
                        icon: const Icon(
                          CupertinoIcons.map,
                          size: AppSpacing.iconMd,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    button: true,
                    label: context.l10n.eventsLocationSiteSemantic(
                      event.siteDistanceKm.toStringAsFixed(1),
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        onTap: () => _openSite(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.radius10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                CupertinoIcons.location_fill,
                                size: AppSpacing.iconMd,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  event.siteName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                context.l10n.eventsLocationDotKm(
                                  event.siteDistanceKm.toStringAsFixed(1),
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasCoords)
                  Semantics(
                    button: true,
                    label: context.l10n.eventsDetailOpenInMaps,
                    child: IconButton(
                      tooltip: context.l10n.eventsDetailOpenInMaps,
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.avatarMd,
                        minHeight: AppSpacing.avatarMd,
                      ),
                      onPressed: () => _openMaps(context),
                      icon: const Icon(
                        CupertinoIcons.map_fill,
                        size: AppSpacing.iconMd,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
