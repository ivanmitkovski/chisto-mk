import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_shimmer_box.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_site_pin_image.dart';
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
    this.useDarkTiles = false,
  });

  final PollutionSite site;
  final LatLng? userLocation;
  final Map<String, LatLng> siteCoordinates;
  final ValueChanged<PollutionSite> onGetDirections;
  final VoidCallback onViewDetails;
  final VoidCallback onDismiss;
  final bool useDarkTiles;

  @override
  State<SitePreviewSheet> createState() => _SitePreviewSheetState();
}

class _SitePreviewSheetState extends State<SitePreviewSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<Offset> _entranceSlide;
  late final Animation<double> _entranceOpacity;
  double _dragAccumulated = 0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.emphasizedDuration,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: AppMotion.smooth,
      ),
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.smooth,
    );
    _entranceController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppHaptics.softTransition(context);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String _formatDistanceFromUser(BuildContext context, PollutionSite site) {
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
        return context.l10n.mapDistanceMetersAway(m.round());
      }
      return context.l10n.mapDistanceKilometersAway(
        (m / 1000).toStringAsFixed(1),
      );
    }
    return context.l10n.mapDistanceKilometersAway(
      site.distanceKm.toStringAsFixed(0),
    );
  }

  void _maybeDismissSwipe(DragEndDetails details) {
    final double v = details.primaryVelocity ?? 0;
    final bool farEnoughDown = _dragAccumulated > 60;
    if (v > 280 || farEnoughDown) {
      if (MediaQuery.supportsAnnounceOf(context)) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          context.l10n.mapPreviewDismissAnnouncement,
          Directionality.of(context),
        );
      }
      AppHaptics.sheetDismiss(context);
      widget.onDismiss();
    } else if (v < -300) {
      AppHaptics.softTransition(context);
      widget.onViewDetails();
    }
    setState(() => _dragAccumulated = 0);
  }

  @override
  Widget build(BuildContext context) {
    final PollutionSite site = widget.site;
    final String distanceLabel = _formatDistanceFromUser(context, site);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        WidgetsBinding
            .instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;

    final Color panelFill = widget.useDarkTiles
        ? AppColors.glassDark.withValues(alpha: 0.55)
        : AppColors.white.withValues(alpha: 0.94);
    final Color panelBorder = widget.useDarkTiles
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.white.withValues(alpha: 0.6);
    final Color titleColor =
        widget.useDarkTiles ? AppColors.textOnDark : AppColors.textPrimary;
    final Color secondaryMuted = widget.useDarkTiles
        ? AppColors.textOnDarkMuted
        : AppColors.textMuted;
    final Color secondaryText = widget.useDarkTiles
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;

    final Widget previewCard =
        Transform.translate(
      offset: Offset(0, _dragAccumulated.clamp(0, 220)),
      child: GestureDetector(
        onVerticalDragUpdate: (DragUpdateDetails d) {
          final double dy = d.delta.dy;
          if (dy > 0) {
            setState(() => _dragAccumulated += dy);
          }
        },
        onVerticalDragEnd: _maybeDismissSwipe,
        onTap: widget.onViewDetails,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: panelFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: panelBorder,
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
                        SitePreviewImage(
                          site: site,
                          dark: widget.useDarkTiles,
                        ),
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
                                      color: titleColor,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  CompactBadge(
                                    label: mapStatusDisplay(
                                      context.l10n,
                                      mapStatusCodeFromUnknown(
                                        site.statusCode ?? site.statusLabel,
                                      ),
                                    ),
                                    color: site.statusColor,
                                    onDarkGlass: widget.useDarkTiles,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.place_outlined,
                                        size: 14,
                                        color: secondaryMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      AnimatedSwitcher(
                                        duration: MediaQuery.disableAnimationsOf(
                                                  context)
                                            ? Duration.zero
                                            : AppMotion.fast,
                                        switchInCurve: AppMotion.smooth,
                                        child: KeyedSubtree(
                                          key: ValueKey<String>(distanceLabel),
                                          child: Text(
                                            distanceLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: secondaryText,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                              AppHaptics.sheetDismiss(context);
                              widget.onDismiss();
                            },
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                            splashFactory: InkSparkle.splashFactory,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: secondaryMuted,
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
                            label: context.l10n.mapPreviewDirections,
                            onTap: () {
                              AppHaptics.light(context);
                              widget.onGetDirections(site);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ActionPill(
                            icon: Icons.arrow_forward_rounded,
                            label: context.l10n.mapPreviewDetails,
                            primary: true,
                            onTap: () {
                              AppHaptics.softTransition(context);
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
      ),
    );

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
              label: context.l10n.mapPreviewSemanticLabel(
                site.title,
                distanceLabel,
              ),
              hint: context.l10n.mapPreviewSemanticHint,
              child: reduceMotion
                  ? previewCard
                  : SlideTransition(
                      position: _entranceSlide,
                      child: FadeTransition(
                        opacity: _entranceOpacity,
                        child: previewCard,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SitePreviewImage extends StatefulWidget {
  const SitePreviewImage({super.key, required this.site, this.dark = false});

  final PollutionSite site;
  final bool dark;

  @override
  State<SitePreviewImage> createState() => _SitePreviewImageState();
}

class _SitePreviewImageState extends State<SitePreviewImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController =
        AnimationController(vsync: this, duration: AppMotion.slow)..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.syncRepeatingShimmer(_shimmerController, context);
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider provider = mapPinImageProviderForSite(widget.site);
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
          image: provider,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (
            BuildContext context,
            Widget child,
            int? frame,
            bool sync,
          ) {
            final bool loaded = sync || frame != null;
            if (loaded) {
              return child;
            }
            return AnimatedBuilder(
              animation: _shimmerController,
              builder: (BuildContext context, Widget? child) => MapSkeletonPulseBox(
                width: 56,
                height: 56,
                radius: 12,
                t: _shimmerController.value,
                dark: widget.dark,
                phase: 0,
              ),
            );
          },
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
    this.onDarkGlass = false,
  });

  final String label;
  final Color color;
  final bool onDarkGlass;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: onDarkGlass ? 0.28 : 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onDarkGlass ? AppColors.textOnDark : color,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
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
