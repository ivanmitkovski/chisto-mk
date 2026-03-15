import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class SitePreviewSheet extends StatefulWidget {
  const SitePreviewSheet({
    super.key,
    required this.site,
    required this.userLocation,
    required this.siteCoordinates,
    required this.onGetDirections,
    required this.onViewDetails,
    required this.onDismiss,
  });

  final PollutionSite site;
  final LatLng? userLocation;
  final Map<String, LatLng> siteCoordinates;
  final ValueChanged<PollutionSite> onGetDirections;
  final VoidCallback onViewDetails;
  final VoidCallback onDismiss;

  @override
  State<SitePreviewSheet> createState() => _SitePreviewSheetState();
}

class _SitePreviewSheetState extends State<SitePreviewSheet> {
  String _formatDistanceFromUser(PollutionSite site) {
    final LatLng? user = widget.userLocation;
    final LatLng? point = widget.siteCoordinates[site.id];
    if (user != null && point != null) {
      final double m = Geolocator.distanceBetween(
        user.latitude,
        user.longitude,
        point.latitude,
        point.longitude,
      );
      if (m < 1000) {
        return '${m.round()} m away';
      }
      return '${(m / 1000).toStringAsFixed(1)} km away';
    }
    return '${site.distanceKm.toStringAsFixed(0)} km';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Semantics(
              label:
                  '${widget.site.title} preview. Swipe up for details, swipe down to dismiss.',
              child: _buildPreviewCard(context, widget.site),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, PollutionSite site) {
    return GestureDetector(
      onVerticalDragEnd: (DragEndDetails details) {
        final double velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) {
          AppHaptics.softTransition();
          widget.onViewDetails();
        } else if (velocity > 300) {
          AppHaptics.sheetDismiss();
          widget.onDismiss();
        }
      },
      onTap: widget.onViewDetails,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SitePreviewImage(site: site),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              site.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                CompactBadge(
                                  label: site.statusLabel,
                                  color: site.statusColor,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.place_outlined,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formatDistanceFromUser(site),
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.sheetDismiss();
                            widget.onDismiss();
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ActionPill(
                          icon: Icons.directions_rounded,
                          label: 'Directions',
                          onTap: () {
                            AppHaptics.light();
                            widget.onGetDirections(site);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ActionPill(
                          icon: Icons.arrow_forward_rounded,
                          label: 'Details',
                          primary: true,
                          onTap: () {
                            AppHaptics.softTransition();
                            widget.onViewDetails();
                          },
                        ),
                      ),
                    ],
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

class SitePreviewImage extends StatelessWidget {
  const SitePreviewImage({super.key, required this.site});

  final PollutionSite site;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      boxShadow: <BoxShadow>[
            BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: site.imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class CompactBadge extends StatelessWidget {
  const CompactBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}

class ActionPill extends StatelessWidget {
  const ActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
        final Color fg = primary ? AppColors.textOnDark : AppColors.primaryDark;
    final Color bg = primary
        ? AppColors.primaryDark
        : AppColors.primary.withValues(alpha: 0.12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
