import 'dart:math' as math;

import 'dart:ui' show ImageFilter;

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
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

/// Key for tests and accessibility drivers targeting the organizer edit control.
const ValueKey<String> kEventDetailHeroEditKey = ValueKey<String>(
  'event_detail_hero_edit',
);

/// Key for tests targeting the hero toolbar chat action.
const ValueKey<String> kEventDetailHeroChatKey = ValueKey<String>(
  'event_detail_hero_chat',
);

/// Radius of trailing toolbar action chips; keep in sync with
/// [_heroToolbarTrailingReservePx].
const double _kHeroToolbarActionChipRadius = 22;

/// Opacity of the solid fill over [BackdropFilter] for the collapsed toolbar
/// (higher when list scrolls underneath so body text does not read through).
const double _kHeroToolbarScrimFillAlphaCollapsed = 0.94;
const double _kHeroToolbarScrimFillAlphaScrolledUnder = 0.98;

/// Start inset for the collapsed toolbar title: [AppBackButton] + leading padding.
double _heroToolbarLeadingReservePx() =>
    AppSpacing.sm + AppSpacing.iconMd * 2;

/// End inset for the collapsed title: trailing `_ActionChip` circles + paddings.
double _heroToolbarTrailingReservePx({
  required bool hasEdit,
  required bool hasChat,
}) {
  final int actionChips = (hasEdit ? 1 : 0) + (hasChat ? 1 : 0);
  if (actionChips == 0) {
    return AppSpacing.sm;
  }
  final double chipDiameter = _kHeroToolbarActionChipRadius * 2;
  return AppSpacing.sm +
      actionChips * chipDiameter +
      (actionChips - 1) * AppSpacing.xs;
}

/// Pinned large top app bar for the event detail screen.
///
/// The expanded state shows the cover image with a cinematic 3-stop gradient
/// overlay. The collapsed state fades in a centred one-line title. The status
/// pill and optional countdown badge are placed at the bottom of the hero and
/// fade away as the bar collapses — this removes the awkward body-top pill jump
/// present when the pill lived in TitleSection.
///
/// [SliverAppBar.pinned] keeps the toolbar visible once the hero has collapsed,
/// matching Material large / medium top app bar behavior. Pass
/// [innerBoxIsScrolled] from the screen scroll position so the frosted toolbar
/// reads as opaque when list content scrolls underneath (Material
/// “scrolled under” affordance without applying theme tint over custom chrome).
///
/// [SliverAppBar.stretch] stays off: stretch plus overscroll can desync the hero layout.
/// Overscroll uses the platform bounce from [eventDetailScrollPhysics].
class HeroImageBar extends StatelessWidget {
  const HeroImageBar({
    super.key,
    required this.event,
    this.onEdit,
    this.enableThumbnailHero = false,
    this.onOpenEventChat,
    this.eventChatUnreadCount = 0,
    this.innerBoxIsScrolled = false,
  });

  final EcoEvent event;

  /// When false, skips [Hero] so route replacements between different event ids do not
  /// trip `_HeroFlight.divert` (see [EventDetailScreen.enableThumbnailHero]).
  final bool enableThumbnailHero;

  /// Organizer edit entry (upcoming/approved events only).
  final VoidCallback? onEdit;

  /// Opens event group chat when the attendee/organizer may access it.
  final VoidCallback? onOpenEventChat;

  /// Unread count for [onOpenEventChat]; ignored when [onOpenEventChat] is null.
  final int eventChatUnreadCount;

  /// When true, the collapsed toolbar frosted strip stays at full opacity (body
  /// content scrolling under the pinned toolbar).
  final bool innerBoxIsScrolled;

  static const double _actionAvatarRadius = _kHeroToolbarActionChipRadius;
  static const double _actionIconSize = 18;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: kEventDetailHeroExpandedHeight,
      pinned: true,
      stretch: false,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: AppColors.transparent,
      leading: const Padding(
        padding: EdgeInsets.only(left: AppSpacing.sm),
        child: Center(child: AppBackButton()),
      ),
      actions: <Widget>[
        if (onEdit != null)
          Padding(
            padding: EdgeInsets.only(
              right: onOpenEventChat != null ? AppSpacing.xs : AppSpacing.sm,
            ),
            child: _ActionChip(
              key: kEventDetailHeroEditKey,
              icon: CupertinoIcons.pencil,
              tooltip: context.l10n.eventsEditEventTitle,
              onTap: onEdit!,
            ),
          ),
        if (onOpenEventChat != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _ActionChip(
              key: kEventDetailHeroChatKey,
              icon: CupertinoIcons.chat_bubble_2,
              tooltip: context.l10n.eventChatRowTitle,
              semanticsLabel: context.l10n.eventsHeroChatSemantic(
                eventChatUnreadCount,
              ),
              badgeCount: eventChatUnreadCount,
              onTap: () {
                AppHaptics.softTransition();
                onOpenEventChat!();
              },
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
          // Fade in a frosted strip as the hero collapses; [innerBoxIsScrolled]
          // keeps it solid while body content scrolls under the pinned toolbar.
          final double linearScrim = (1.0 - expandRatio).clamp(0.0, 1.0);
          // Once the hero is past ~full expansion, keep the toolbar strip opaque
          // enough that list rows never read through (linear alone stays too low
          // in the middle of the collapse range).
          final double scrimOpacity = innerBoxIsScrolled
              ? 1.0
              : (expandRatio < 0.98
                  ? math.max(linearScrim, 0.92)
                  : linearScrim);
          final double scrimFillAlpha = innerBoxIsScrolled
              ? _kHeroToolbarScrimFillAlphaScrolledUnder
              : _kHeroToolbarScrimFillAlphaCollapsed;
          final double topInset = MediaQuery.paddingOf(context).top;
          final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

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
              if (scrimOpacity > 0.01)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: scrimOpacity,
                      child: ClipRect(
                        child: reduceMotion
                            ? ColoredBox(
                                color: AppColors.appBackground,
                                child: SizedBox(
                                  height: topInset + kToolbarHeight,
                                  width: double.infinity,
                                ),
                              )
                            : BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 18,
                                  sigmaY: 18,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.appBackground.withValues(
                                      alpha: scrimFillAlpha,
                                    ),
                                  ),
                                  child: SizedBox(
                                    height: topInset + kToolbarHeight,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                      ),
                    ),
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
                          padding: EdgeInsetsDirectional.fromSTEB(
                            _heroToolbarLeadingReservePx(),
                            0,
                            _heroToolbarTrailingReservePx(
                              hasEdit: onEdit != null,
                              hasChat: onOpenEventChat != null,
                            ),
                            0,
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
    this.semanticsLabel,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// When set, used as the [Semantics] label instead of [tooltip] (e.g. unread).
  final String? semanticsLabel;

  /// When &gt; 0, shows a small unread badge on the chip.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget iconButton = IconButton(
      iconSize: HeroImageBar._actionIconSize,
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      icon: Icon(
        icon,
        size: HeroImageBar._actionIconSize,
        color: AppColors.textPrimary,
      ),
    );

    final Widget avatar = CircleAvatar(
      radius: HeroImageBar._actionAvatarRadius,
      backgroundColor: AppColors.appBackground.withValues(alpha: 0.85),
      child: iconButton,
    );

    return Semantics(
      button: true,
      label: semanticsLabel ?? tooltip,
      child: badgeCount > 0
          ? Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                avatar,
                Positioned(
                  right: 2,
                  top: 2,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: AppTypography.eventsUnreadCountBadge(textTheme),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : avatar,
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
