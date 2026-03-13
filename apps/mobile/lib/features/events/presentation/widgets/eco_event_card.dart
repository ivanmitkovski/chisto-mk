import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
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
        borderRadius: BorderRadius.circular(20),
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
            color: Colors.black.withValues(alpha: _pressed ? 0.02 : 0.05),
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
                        Text('Checked in', style: textTheme.bodySmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ],
                  if (event.hasAfterImages && !event.isCheckedIn) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        const Icon(CupertinoIcons.camera_fill, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xxs),
                        Text('${event.afterImagePaths.length} cleanup photos', style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: 12)),
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
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.softTransition();
                  widget.onTap();
                },
                borderRadius: BorderRadius.circular(20),
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
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetCtx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(CupertinoIcons.doc_on_doc),
                title: const Text('Copy event details'),
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
                ListTile(
                  leading: const Icon(CupertinoIcons.share),
                  title: const Text('Share event'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    widget.onShare?.call();
                  },
                ),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_right_circle),
                title: const Text('Open event'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  widget.onTap();
                },
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Thumbnail with Hero support
// ---------------------------------------------------------------------------

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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                errorBuilder: (_, __, ___) => Container(color: AppColors.inputFill),
              ),
            );
          },
        );
      },
      child: image,
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip with optional live pulse
// ---------------------------------------------------------------------------

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: widget.status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Starting soon" badge
// ---------------------------------------------------------------------------

class _StartingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentWarning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Soon',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.accentWarningDark,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Participant row with stacked avatars
// ---------------------------------------------------------------------------

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
          style: TextStyle(
            fontSize: 12,
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
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Distance badge
// ---------------------------------------------------------------------------

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            CupertinoIcons.location_solid,
            size: 10,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 3),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Three-dot menu
// ---------------------------------------------------------------------------

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
