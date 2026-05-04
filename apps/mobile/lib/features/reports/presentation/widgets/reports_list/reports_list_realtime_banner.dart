import 'dart:async';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Surfaces reports realtime issues after a short delay for transient Socket.IO churn;
/// [ReportsRealtimeConnectionState.offline] is shown immediately.
class ReportsListRealtimeBanner extends StatefulWidget {
  const ReportsListRealtimeBanner({super.key});

  @override
  State<ReportsListRealtimeBanner> createState() =>
      _ReportsListRealtimeBannerState();
}

class _ReportsListRealtimeBannerState extends State<ReportsListRealtimeBanner> {
  static const Duration _kSustainNonLive = Duration(milliseconds: 2500);
  Timer? _sustainTimer;
  bool _surfaceIssue = false;

  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.reportsRealtimeService.connectionState.addListener(
      _onConnectionStateChanged,
    );
    _apply(
      ServiceLocator.instance.reportsRealtimeService.connectionState.value,
    );
  }

  @override
  void dispose() {
    _sustainTimer?.cancel();
    ServiceLocator.instance.reportsRealtimeService.connectionState.removeListener(
      _onConnectionStateChanged,
    );
    super.dispose();
  }

  void _onConnectionStateChanged() {
    _apply(
      ServiceLocator.instance.reportsRealtimeService.connectionState.value,
    );
  }

  void _apply(ReportsRealtimeConnectionState? raw) {
    final ReportsRealtimeConnectionState s =
        raw ?? ReportsRealtimeConnectionState.live;
    _sustainTimer?.cancel();
    _sustainTimer = null;

    if (s == ReportsRealtimeConnectionState.live) {
      if (_surfaceIssue) {
        setState(() => _surfaceIssue = false);
      }
      return;
    }

    if (s == ReportsRealtimeConnectionState.connecting) {
      _sustainTimer?.cancel();
      _sustainTimer = null;
      if (_surfaceIssue) {
        setState(() => _surfaceIssue = false);
      }
      return;
    }

    // Socket.IO uses this during normal backoff; surfacing it reads as a permanent error.
    if (s == ReportsRealtimeConnectionState.reconnecting) {
      _sustainTimer?.cancel();
      _sustainTimer = null;
      if (_surfaceIssue) {
        setState(() => _surfaceIssue = false);
      }
      return;
    }

    if (s == ReportsRealtimeConnectionState.offline) {
      if (!_surfaceIssue) {
        setState(() => _surfaceIssue = true);
      }
      return;
    }

    _sustainTimer = Timer(_kSustainNonLive, () {
      if (!mounted) {
        return;
      }
      final ReportsRealtimeConnectionState cur =
          ServiceLocator.instance.reportsRealtimeService.connectionState.value ??
              ReportsRealtimeConnectionState.live;
      if (cur == ReportsRealtimeConnectionState.live) {
        return;
      }
      setState(() => _surfaceIssue = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_surfaceIssue) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = context.l10n;
    return ValueListenableBuilder<ReportsRealtimeConnectionState?>(
      valueListenable: ServiceLocator.instance.reportsRealtimeService.connectionState,
      builder: (
        BuildContext context,
        ReportsRealtimeConnectionState? value,
        Widget? _,
      ) {
        final ReportsRealtimeConnectionState s =
            value ?? ReportsRealtimeConnectionState.live;
        if (s == ReportsRealtimeConnectionState.live) {
          return const SizedBox.shrink();
        }
        if (s == ReportsRealtimeConnectionState.connecting ||
            s == ReportsRealtimeConnectionState.reconnecting) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<int>(
          valueListenable:
              ServiceLocator.instance.reportsRealtimeService.reconnectStreakSinceLive,
          builder: (BuildContext context, int streak, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Material(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (s == ReportsRealtimeConnectionState.offline)
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 18,
                          color: AppColors.primary,
                        )
                      else
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.reportsSseReconnectBanner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (streak > 3 &&
                          s != ReportsRealtimeConnectionState.offline)
                        TextButton(
                          onPressed: () {
                            ServiceLocator.instance.reportsRealtimeService
                                .requestReconnect();
                          },
                          child: Text(l10n.reportsSseReconnectAction),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
