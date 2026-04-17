import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_layout.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

/// Key for tests and accessibility drivers targeting the organizer edit control.
const ValueKey<String> kEventDetailHeroEditKey = ValueKey<String>(
  'event_detail_hero_edit',
);

/// Pinned, stretchable hero sliver for the event detail screen.
///
/// The expanded state shows the cover image with a cinematic 3-stop gradient
/// overlay. The collapsed state fades in a centred one-line title. The status
/// pill and optional countdown badge are placed at the bottom of the hero and
/// fade away as the bar collapses — this removes the awkward body-top pill jump
/// present when the pill lived in TitleSection.
class HeroImageBar extends StatelessWidget {
  const HeroImageBar({
    super.key,
    required this.event,
    required this.onShare,
    this.onEdit,
    this.enableThumbnailHero = false,
    this.shareButtonKey,
  });

  final EcoEvent event;
  final VoidCallback onShare;

  /// When set, pinned to the share action for [Share.shareUri] popover anchoring.
  final GlobalKey? shareButtonKey;

  /// When false, skips [Hero] so route replacements between different event ids do not
  /// trip `_HeroFlight.divert` (see [EventDetailScreen.enableThumbnailHero]).
  final bool enableThumbnailHero;

  /// Organizer edit entry (upcoming/approved events only).
  final VoidCallback? onEdit;

  static const double _actionAvatarRadius = 22;
  static const double _actionIconSize = 18;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: kEventDetailHeroExpandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.panelBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: const Padding(
        padding: EdgeInsets.only(left: AppSpacing.sm),
        child: Center(child: AppBackButton()),
      ),
      actions: <Widget>[
        if (onEdit != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _ActionChip(
              key: kEventDetailHeroEditKey,
              icon: CupertinoIcons.pencil,
              tooltip: context.l10n.eventsEditEventTitle,
              onTap: onEdit!,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: _ActionChip(
            key: shareButtonKey,
            icon: CupertinoIcons.share,
            tooltip: context.l10n.eventsShareEventTooltip,
            onTap: onShare,
          ),
        ),
      ],
      // Keep the [Hero] subtree geometry stable (no per-frame [Transform.scale]).
      // Animated layout inside a Hero + [SliverAppBar] is a common source of
      // _HeroFlight.divert / overlayEntry crashes when popping or stacking routes.
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double expandRatio =
              ((constraints.maxHeight - kToolbarHeight) /
                      (kEventDetailHeroExpandedHeight - kToolbarHeight))
                  .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _thumbnailHeroOrPlain(
                      context: context,
                      event: event,
                      enableHero: enableThumbnailHero,
                    ),
                    // 3-stop cinematic gradient: transparent → tinted → dark
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const <double>[0.0, 0.45, 1.0],
                          colors: <Color>[
                            AppColors.black.withValues(alpha: 0.04),
                            AppColors.black.withValues(alpha: 0.18),
                            AppColors.black.withValues(
                              alpha: 0.52 + (1 - expandRatio) * 0.12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Hero bottom bar: status pill + countdown ──────────
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Opacity(
                        opacity: expandRatio,
                        child: Row(
                          children: <Widget>[
                            _StatusPill(event: event),
                            if (event.status ==
                                EcoEventStatus.upcoming) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              CountdownBadge(event: event),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Collapsed title ──────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1.0 - expandRatio * 1.5).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kHeroToolbarTitleInset,
                          ),
                          child: Center(
                            child: _CollapsedToolbarTitle(title: event.title),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _thumbnailHeroOrPlain({
  required BuildContext context,
  required EcoEvent event,
  required bool enableHero,
}) {
  final Widget cover = SizedBox.expand(
    child: Semantics(
      image: true,
      label: context.l10n.eventsDetailCoverSemantic(event.title),
      child: EcoEventCoverImage(
        path: event.siteImageUrl,
        fit: BoxFit.cover,
        imageUnavailableLabel: context.l10n.eventsDetailCoverImageUnavailable,
      ),
    ),
  );
  final Widget materialCover = Material(
    type: MaterialType.transparency,
    child: cover,
  );
  if (!enableHero) {
    return materialCover;
  }
  return Hero(tag: 'event-thumb-${event.id}', child: materialCover);
}

// ────────────────────────────────────────────────────────────────────────────
// Private helpers
// ────────────────────────────────────────────────────────────────────────────

class _CollapsedToolbarTitle extends StatelessWidget {
  const _CollapsedToolbarTitle({required this.title});

  final String title;

  static const int _tooltipCharThreshold = 28;

  @override
  Widget build(BuildContext context) {
    final TextTheme theme = Theme.of(context).textTheme;
    final TextStyle baseTitleSmall =
        theme.titleSmall ?? AppTypography.textTheme.titleSmall!;
    final Text text = Text(
      title,
      style: baseTitleSmall.copyWith(color: AppColors.textPrimary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    final Widget labeled = Semantics(label: title, child: text);

    if (title.characters.length <= _tooltipCharThreshold) {
      return labeled;
    }
    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      message: title,
      child: labeled,
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: CircleAvatar(
        radius: HeroImageBar._actionAvatarRadius,
        backgroundColor: AppColors.appBackground.withValues(alpha: 0.85),
        child: IconButton(
          iconSize: HeroImageBar._actionIconSize,
          tooltip: tooltip,
          onPressed: onTap,
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            size: HeroImageBar._actionIconSize,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Translucent pill showing the event status, rendered over the hero image.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        event.status.localizedLabel(context.l10n),
        style: AppTypography.pillLabel.copyWith(
          fontSize: 12,
          color: AppColors.white,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class CountdownBadge extends StatelessWidget {
  const CountdownBadge({super.key, required this.event});
  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final Duration diff = event.startDateTime.difference(DateTime.now());
    if (diff.isNegative) {
      return const SizedBox.shrink();
    }

    final String label = eventsCountdownLabel(
      context.l10n,
      event.startDateTime,
    );

    return Semantics(
      label: context.l10n.eventsCountdownBadgeSemantic(label),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(CupertinoIcons.clock, size: 13, color: AppColors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.eventsCaptionStrong(
                Theme.of(context).textTheme,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
