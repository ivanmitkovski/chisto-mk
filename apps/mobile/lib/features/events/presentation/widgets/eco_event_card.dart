import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class EcoEventCard extends StatefulWidget {
  const EcoEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isHero = false,
    this.onJoin,
    this.onShare,
  });

  final EcoEvent event;
  final VoidCallback onTap;
  final bool isHero;
  final VoidCallback? onJoin;
  final VoidCallback? onShare;

  @override
  State<EcoEventCard> createState() => _EcoEventCardState();
}

class _EcoEventCardState extends State<EcoEventCard> {
  bool _pressed = false;

  bool get _isStartingSoon {
    if (widget.event.status != EcoEventStatus.upcoming) return false;
    final Duration diff = widget.event.startDateTime.difference(DateTime.now());
    return diff.inHours < 24 && !diff.isNegative;
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent event = widget.event;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isCancelled = event.status == EcoEventStatus.cancelled;

    Widget card = AnimatedContainer(
      duration: AppMotion.xFast,
      curve: AppMotion.emphasized,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: event.status == EcoEventStatus.inProgress
            ? Border(
                left: BorderSide(
                  color: event.status.color.withValues(alpha: 0.5),
                  width: 3,
                ),
              )
            : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: _pressed ? 0.02 : 0.05),
            blurRadius: _pressed ? 6 : 14,
            offset: Offset(0, _pressed ? 2 : 5),
          ),
        ],
      ),
      child: Opacity(
        opacity: isCancelled ? 0.55 : 1.0,
        child: Row(
          children: <Widget>[
            _Thumbnail(
              imageAsset: event.siteImageUrl,
              heroTag: 'event-thumb-${event.id}',
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _StatusChip(
                        status: event.status,
                        isLive: event.status == EcoEventStatus.inProgress,
                      ),
                      if (_isStartingSoon) ...<Widget>[
                        const SizedBox(width: AppSpacing.xxs),
                        _StartingSoonBadge(),
                      ],
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          event.formattedTimeRange,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      _MoreButton(
                        onTap: () => _openMoreActions(context, event),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          event.siteName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      _DistanceBadge(km: event.siteDistanceKm),
                    ],
                  ),
                  if (event.participantCount > 0) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    _ParticipantRow(
                      count: event.participantCount,
                      maxParticipants: event.maxParticipants,
                      organizerName: event.organizerName,
                    ),
                  ],
                  if (event.isCheckedIn) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        const Icon(CupertinoIcons.checkmark_circle_fill, size: 14, color: AppColors.primaryDark),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          context.l10n.eventsCheckedInBadge,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.hasAfterImages && !event.isCheckedIn) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        const Icon(CupertinoIcons.camera_fill, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          context.l10n.eventsCleanupPhotosCount(
                            event.afterImagePaths.length,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
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
    );

    return Semantics(
      button: true,
      label: '${event.title}, ${event.formattedDate}, ${event.status.label}',
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
              color: AppColors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.softTransition();
                  widget.onTap();
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: card,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMoreActions(BuildContext context, EcoEvent event) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: AppSpacing.sheetHandle,
                      height: AppSpacing.sheetHandleHeight,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Event actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _EventActionTile(
                    icon: CupertinoIcons.doc_on_doc,
                    title: 'Copy event details',
                    subtitle: 'Copy title, date and location',
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '${event.title}\n${event.formattedDate} (${event.formattedTimeRange})\n${event.siteName}',
                        ),
                      );
                      Navigator.of(sheetCtx).pop();
                      if (mounted) {
                        AppSnack.show(
                          this.context,
                          message: 'Event details copied.',
                          type: AppSnackType.success,
                        );
                      }
                    },
                  ),
                  if (widget.onShare != null)
                    _EventActionTile(
                      icon: CupertinoIcons.share,
                      title: 'Share event',
                      subtitle: 'Share with friends',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        widget.onShare?.call();
                      },
                    ),
                  _EventActionTile(
                    icon: CupertinoIcons.arrow_right_circle,
                    title: 'Open event',
                    subtitle: 'View full event details',
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      widget.onTap();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.imageAsset,
    required this.heroTag,
  });

  final String imageAsset;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius14),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          border: Border.all(
            color: AppColors.white,
            width: 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) {
              return Container(
                color: AppColors.inputFill,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              );
            },
          ),
        ),
      ),
    );

    return Hero(
      tag: heroTag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(
                14 * (1 - animation.value) + 0 * animation.value,
              ),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: AppColors.inputFill),
              ),
            );
          },
        );
      },
      child: image,
    );
  }
}

class _StatusChip extends StatefulWidget {
  const _StatusChip({
    required this.status,
    this.isLive = false,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs / 2),
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
            widget.status.label,
            style: AppTypography.badgeLabel.copyWith(
              color: widget.status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs / 2),
      decoration: BoxDecoration(
        color: AppColors.accentWarning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'Soon',
        style: AppTypography.badgeLabel.copyWith(
          fontSize: 10,
          color: AppColors.accentWarningDark,
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.count,
    this.maxParticipants,
    required this.organizerName,
  });

  final int count;
  final int? maxParticipants;
  final String organizerName;

  @override
  Widget build(BuildContext context) {
    final int showCount = count.clamp(0, 4);
    final int overflow = count - showCount;

    return Row(
      children: <Widget>[
        SizedBox(
          width: showCount * 16.0 + 4,
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 0; i < showCount; i++)
                Positioned(
                  left: i * 14.0,
                  child: _MiniAvatar(
                    label: i == 0 ? organizerName : 'P$i',
                    index: i,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          overflow > 0
              ? '+$overflow more'
              : maxParticipants != null
                  ? '$count / $maxParticipants'
                  : '$count joined',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.label, required this.index});

  final String label;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarPalette[index % AppColors.avatarPalette.length],
        border: Border.all(color: AppColors.panelBackground, width: 1.5),
      ),
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: AppTypography.badgeLabel.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.km});

  final double km;

  String get _label {
    if (km < 0.1) return '<100 m';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs / 2),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            CupertinoIcons.location_solid,
            size: 10,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            _label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'More event actions',
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(
            CupertinoIcons.ellipsis,
            size: 18,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _EventActionTile extends StatelessWidget {
  const _EventActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              color: AppColors.inputFill.withValues(alpha: 0.6),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.textPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
