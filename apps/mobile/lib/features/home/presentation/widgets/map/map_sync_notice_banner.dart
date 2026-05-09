import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_inline_notice.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Slim pill below the toolbar when [MapSitesState.syncNotice] is shown.
class MapSyncNoticeBanner extends StatefulWidget {
  const MapSyncNoticeBanner({
    super.key,
    required this.notice,
    required this.useDarkTiles,
    required this.onTapSync,
  });

  final MapSyncInlineNotice notice;
  final bool useDarkTiles;
  final VoidCallback onTapSync;

  @override
  State<MapSyncNoticeBanner> createState() => _MapSyncNoticeBannerState();
}

class _MapSyncNoticeBannerState extends State<MapSyncNoticeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _scheduledStart = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduledStart) {
      return;
    }
    _scheduledStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (MediaQuery.disableAnimationsOf(context)) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String message = widget.notice.localize(context.l10n);
    final Color fg = widget.useDarkTiles ? AppColors.textOnDark : AppColors.textPrimary;
    final Color iconFg =
        widget.useDarkTiles ? AppColors.textOnDarkMuted : AppColors.textMuted;
    final Color fill = widget.useDarkTiles
        ? AppColors.glassDark.withValues(alpha: 0.62)
        : AppColors.white.withValues(alpha: 0.76);
    final Color border = widget.useDarkTiles
        ? AppColors.white.withValues(alpha: 0.14)
        : AppColors.white.withValues(alpha: 0.65);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.22),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: AppMotion.smooth,
        ),
      ),
      child: FadeTransition(
        opacity: _entranceController,
        child: Semantics(
          button: true,
          label:
              '$message ${context.l10n.mapSyncNoticeSemanticRefreshHint}',
          child: Material(
            color: AppColors.transparent,
            elevation: 0,
            child: InkWell(
              onTap: widget.onTapSync,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      color: fill,
                      border: Border.all(color: border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.sync_problem_rounded,
                            size: 18,
                            color: iconFg,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: widget.useDarkTiles
                                ? AppColors.primary
                                : AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on MapSyncInlineNotice {
  String localize(AppLocalizations l10n) {
    switch (kind) {
      case MapSyncInlineNoticeKind.liveUpdatesDelayed:
        return l10n.mapSyncLiveUpdatesDelayed;
      case MapSyncInlineNoticeKind.connectionUnstable:
        return l10n.mapSyncConnectionUnstable;
      case MapSyncInlineNoticeKind.offlineCached:
        final DateTime? at = cachedAt;
        if (at == null) {
          return l10n.mapSyncOfflineSnapshot;
        }
        final Duration age = DateTime.now().difference(at);
        if (age.inMinutes < 1) {
          return l10n.mapSyncOfflineSnapshotJustNow;
        }
        if (age.inHours < 1) {
          return l10n.mapSyncOfflineSnapshotMinutesAgo(age.inMinutes);
        }
        return l10n.mapSyncOfflineSnapshotHoursAgo(age.inHours);
    }
  }
}
