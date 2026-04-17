import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_share_payload.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';

class EcoEventCard extends StatefulWidget {
  const EcoEventCard({
    super.key,
    required this.event,
    required this.onTap,

    /// When true, the thumbnail uses a [Hero] for transitions (off by default: unstable with
    /// [SliverAppBar] + route replacement; see `hero_image_bar.dart`).
    this.enableThumbnailHero = false,
    this.onJoin,
    this.onShare,
  });

  final EcoEvent event;
  final VoidCallback onTap;
  final bool enableThumbnailHero;
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

    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Color dividerEdge = AppColors.divider.withValues(alpha: 0.75);
    final BorderRadius cardRadius =
        BorderRadius.circular(AppSpacing.radiusCard);
    final bool liveAccent = event.status == EcoEventStatus.inProgress;

    Widget card = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppMotion.xFast,
      curve: AppMotion.emphasized,
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: cardRadius,
        border: Border.all(color: dividerEdge),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: _pressed ? AppSpacing.sm : AppSpacing.md,
            offset: Offset(0, _pressed ? 2 : 4),
          ),
          if (!_pressed)
            BoxShadow(
              color: AppColors.shadowMedium,
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
                          '${formatEventCalendarDate(context, event.date)} · ${event.formattedTimeRange}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eventsListCardMeta(textTheme),
                        ),
                      ),
                      _MoreButton(
                        onTap: () => _openMoreActions(context, event),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eventsListCardTitle(textTheme)
                              .copyWith(
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.textMuted,
                              ),
                        ),
                      ),
                      if (event.isRecurring) ...<Widget>[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.repeat,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 14,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          event.siteName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eventsListCardMeta(textTheme),
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
                      organizerAvatarUrl: event.organizerAvatarUrl,
                      organizerId: event.organizerId,
                    ),
                  ],
                  if (event.isCheckedIn) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          context.l10n.eventsCheckedInBadge,
                          style: AppTypography.eventsCardBadgeAccent(
                            textTheme,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.hasAfterImages && !event.isCheckedIn) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        const Icon(
                          CupertinoIcons.camera_fill,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          context.l10n.eventsCleanupPhotosCount(
                            event.afterImagePaths.length,
                          ),
                          style: AppTypography.eventsCardBadgeMuted(textTheme),
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

    return Semantics(
      button: true,
      label:
          '${event.title}, ${formatEventCalendarDate(context, event.date)}, ${event.status.localizedLabel(context.l10n)}',
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
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
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext sheetCtx) {
        final l10n = sheetCtx.l10n;
        return ReportSheetScaffold(
          title: l10n.eventsCardActionsSheetTitle,
          subtitle: event.title,
          fitToContent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ReportActionTile(
                icon: CupertinoIcons.doc_on_doc,
                title: l10n.eventsCardCopyTitle,
                subtitle: l10n.eventsCardCopySubtitle,
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: buildEventSharePlainText(
                        sheetCtx,
                        event,
                        AppConfig.shareBaseUrlFromEnvironment,
                      ),
                    ),
                  );
                  Navigator.of(sheetCtx).pop();
                  if (mounted) {
                    AppSnack.show(
                      this.context,
                      message: l10n.eventsCardCopiedSnack,
                      type: AppSnackType.success,
                    );
                  }
                },
              ),
              if (widget.onShare != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                ReportActionTile(
                  icon: CupertinoIcons.share,
                  title: l10n.eventsCardShareTitle,
                  subtitle: l10n.eventsCardShareSubtitle,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    widget.onShare?.call();
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              ReportActionTile(
                icon: CupertinoIcons.arrow_right_circle,
                title: l10n.eventsCardOpenTitle,
                subtitle: l10n.eventsCardOpenSubtitle,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  widget.onTap();
                },
              ),
            ],
          ),
        );
      },
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
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius14),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          border: Border.all(color: AppColors.white, width: 2),
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
          child: EcoEventCoverImage(
            path: imageAsset,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorWidget: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textMuted,
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

class _StartingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentWarning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        context.l10n.eventsCardSoonLabel,
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
    this.organizerAvatarUrl,
    required this.organizerId,
  });

  final int count;
  final int? maxParticipants;
  final String organizerName;
  final String? organizerAvatarUrl;
  final String organizerId;

  @override
  Widget build(BuildContext context) {
    final int showCount = count.clamp(0, 4);
    final int overflow = count - showCount;

    const double miniSize = 20;
    const double miniBorder = 1.5;
    final double miniOuter = miniSize + 2 * miniBorder;
    const double miniStride = 14.0;

    return Row(
      children: <Widget>[
        SizedBox(
          width: miniOuter + (showCount - 1) * miniStride,
          height: miniOuter,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 0; i < showCount; i++)
                Positioned(
                  left: i * miniStride,
                  child: _MiniAvatar(
                    label: i == 0
                        ? organizerName
                        : String.fromCharCode(0x40 + i),
                    imageUrl: i == 0 ? organizerAvatarUrl : null,
                    seed: i == 0 ? organizerId : '${organizerId}_mini_$i',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          overflow > 0
              ? context.l10n.eventsCardParticipantsMore(overflow)
              : maxParticipants != null
              ? context.l10n.eventsCardParticipantsCountMax(
                  count,
                  maxParticipants!,
                )
              : context.l10n.eventsCardParticipantsJoined(count),
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
  const _MiniAvatar({required this.label, this.imageUrl, required this.seed});

  final String label;
  final String? imageUrl;
  final String seed;

  @override
  Widget build(BuildContext context) {
    const double size = 20;
    const double borderW = 1.5;
    final double outer = size + 2 * borderW;
    return Container(
      width: outer,
      height: outer,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.panelBackground, width: borderW),
      ),
      clipBehavior: Clip.antiAlias,
      child: UserAvatarCircle(
        displayName: label,
        imageUrl: imageUrl,
        size: size,
        seed: seed,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs / 2,
      ),
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
      label: context.l10n.eventsCardMoreActionsSemantic,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
        ),
        icon: const Icon(
          CupertinoIcons.ellipsis,
          size: 18,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
