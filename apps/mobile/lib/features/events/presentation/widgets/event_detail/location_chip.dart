import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class LocationChip extends StatelessWidget {
  const LocationChip({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View pollution site, ${event.siteDistanceKm.toStringAsFixed(1)} km away',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.softTransition();
            final PollutionSite site = EventSiteResolver.resolveSiteForEvent(
              event,
            );
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (BuildContext context) =>
                    PollutionSiteDetailScreen(site: site),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.radius10,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  CupertinoIcons.location_fill,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    event.siteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '· ${event.siteDistanceKm.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.primaryDark.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
