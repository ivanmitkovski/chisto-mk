import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/ellipsize_words_to_max_width.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EcoEventCard extends StatefulWidget {
  const EcoEventCard({
    super.key,
    required this.event,
    required this.onTap,

    /// When true, the thumbnail uses a [Hero] for transitions (off by default: unstable with
    /// [SliverAppBar] + route replacement; see `hero_image_bar.dart`).
    this.enableThumbnailHero = false,
  });

  final EcoEvent event;
  final VoidCallback onTap;
  final bool enableThumbnailHero;

  @override
  State<EcoEventCard> createState() => _EcoEventCardState();
}

String _ecoEventCardDistanceLabel(BuildContext context, double km) {
  if (km < 0.1) {
    return context.l10n.eventsDistanceLessThan100m;
  }
  if (km < 1) {
    return context.l10n.eventsDistanceMeters((km * 1000).round());
  }
  return context.l10n.eventsDistanceKilometers(km.toStringAsFixed(1));
}

class _EcoEventCardState extends State<EcoEventCard> {
  bool _pressed = false;

  bool get _isStartingSoon {
    if (widget.event.status != EcoEventStatus.upcoming) return false;
    final Duration diff = widget.event.startDateTime.difference(DateTime.now());
    return diff.inHours < 24 && !diff.isNegative;
  }

  String _participantTail(BuildContext context) {
    if (widget.event.participantCount <= 0) {
      return '';
    }
    return ' · ${context.l10n.eventsCardParticipantsJoined(widget.event.participantCount)}';
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent event = widget.event;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isCancelled = event.status == EcoEventStatus.cancelled;

    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Color dividerEdge = colorScheme.outlineVariant.withValues(alpha: 0.75);
    final BorderRadius cardRadius =
        BorderRadius.circular(AppSpacing.radiusCard);
    final bool liveAccent = event.status == EcoEventStatus.inProgress;

    final TextStyle metaStyle = AppTypography.eventsListCardMeta(textTheme);

    Widget card = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppMotion.xFast,
      curve: AppMotion.emphasized,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: cardRadius,
        border: Border.all(color: dividerEdge),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: _pressed ? AppSpacing.sm : AppSpacing.md,
            offset: Offset(0, _pressed ? 2 : 4),
          ),
          if (!_pressed)
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: AppSpacing.lg,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            if (liveAccent)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ColoredBox(
                  color: event.status.color.withValues(alpha: 0.55),
                  child: const SizedBox(width: 3),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Opacity(
                opacity: isCancelled ? 0.55 : 1.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Thumbnail(
                      imageAsset: event.siteImageUrl,
                      heroTag: widget.enableThumbnailHero
                          ? 'event-thumb-${event.id}'
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.eventsListCardTitle(textTheme)
                                      .copyWith(
                                        decoration: isCancelled
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              if (event.isRecurring) ...<Widget>[
                                const SizedBox(width: AppSpacing.xxs),
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    top: 2,
                                    start: 2,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.repeat,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.95),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (event.status == EcoEventStatus.inProgress)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                _StatusChip(
                                  status: event.status,
                                  isLive: true,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    '${formatEventCalendarDate(context, event.date)} · ${event.formattedTimeRange}'
                                    '${_isStartingSoon ? ' · ${context.l10n.eventsCardSoonLabel}' : ''}'
                                    '${_participantTail(context)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: metaStyle,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text.rich(
                              TextSpan(
                                style: metaStyle,
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: event.status.localizedLabel(context.l10n),
                                    style: TextStyle(
                                      color: event.status.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' · ${formatEventCalendarDate(context, event.date)} · ${event.formattedTimeRange}',
                                  ),
                                  if (_isStartingSoon)
                                    TextSpan(
                                      text: ' · ${context.l10n.eventsCardSoonLabel}',
                                      style: metaStyle.copyWith(
                                        color: colorScheme.tertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (event.participantCount > 0)
                                    TextSpan(
                                      text:
                                          ' · ${context.l10n.eventsCardParticipantsJoined(event.participantCount)}',
                                      style: metaStyle.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                CupertinoIcons.location_solid,
                                size: 14,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Expanded(
                                child: LayoutBuilder(
                                  builder:
                                      (BuildContext context, BoxConstraints constraints) {
                                    final TextDirection direction =
                                        Directionality.maybeOf(context) ??
                                            TextDirection.ltr;
                                    final TextScaler textScaler =
                                        MediaQuery.textScalerOf(context);
                                    final TextStyle siteStyle = metaStyle;
                                    final TextStyle distStyle = metaStyle.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    );
                                    final String suffix =
                                        ' · ${_ecoEventCardDistanceLabel(context, event.siteDistanceKm)}';
                                    final TextPainter suffixPainter = TextPainter(
                                      text: TextSpan(text: suffix, style: distStyle),
                                      textDirection: direction,
                                      maxLines: 1,
                                      textScaler: textScaler,
                                    )..layout();
                                    final double siteMaxWidth = math.max(
                                      0,
                                      constraints.maxWidth - suffixPainter.width,
                                    );
                                    final String siteShown = ellipsizeWordsToMaxWidth(
                                      event.siteName,
                                      siteStyle,
                                      siteMaxWidth,
                                      direction,
                                      textScaler,
                                    );
                                    return Text.rich(
                                      TextSpan(
                                        children: <InlineSpan>[
                                          TextSpan(text: siteShown, style: siteStyle),
                                          TextSpan(text: suffix, style: distStyle),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (event.isCheckedIn) ...<Widget>[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: <Widget>[
                                Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  context.l10n.eventsCheckedInBadge,
                                  style: AppTypography.eventsCardBadgeAccent(
                                    textTheme,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final StringBuffer a11y = StringBuffer()
      ..write(event.title)
      ..write(', ')
      ..write(formatEventCalendarDate(context, event.date))
      ..write(', ')
      ..write(event.status.localizedLabel(context.l10n));
    if (event.participantCount > 0) {
      a11y
        ..write(', ')
        ..write(context.l10n.eventsCardParticipantsJoined(event.participantCount));
    }
    if (event.siteName.trim().isNotEmpty) {
      a11y
        ..write(', ')
        ..write(event.siteName);
    }

    return Semantics(
      button: true,
      label: a11y.toString(),
      child: RepaintBoundary(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: AppMotion.xFast,
            curve: AppMotion.emphasized,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.softTransition();
                  widget.onTap();
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                child: card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageAsset, required this.heroTag});

  final String imageAsset;

  /// When null, no [Hero] — avoids duplicate `event-thumb-*` tags on the feed.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius14),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          border: Border.all(color: colorScheme.surface, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: EcoEventCoverImage(
            path: imageAsset,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorWidget: Icon(
              Icons.image_not_supported_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
        ),
      ),
    );

    if (heroTag == null) {
      return image;
    }

    return Hero(
      tag: heroTag!,
      child: Material(type: MaterialType.transparency, child: image),
    );
  }
}

class _StatusChip extends StatefulWidget {
  const _StatusChip({required this.status, this.isLive = false});

  final EcoEventStatus status;
  final bool isLive;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs / 2,
      ),
      decoration: BoxDecoration(
        color: widget.status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.isLive) ...<Widget>[
            _pulseController != null
                ? AnimatedBuilder(
                    animation: _pulseController!,
                    builder: (BuildContext context, Widget? child) {
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.status.color.withValues(
                            alpha: 0.6 + 0.4 * _pulseController!.value,
                          ),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            widget.status.localizedLabel(context.l10n),
            style: AppTypography.badgeLabel.copyWith(
              color: widget.status.color,
            ),
          ),
        ],
      ),
    );
  }
}
