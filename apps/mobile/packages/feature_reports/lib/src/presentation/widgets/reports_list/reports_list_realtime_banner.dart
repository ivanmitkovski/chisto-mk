import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows when reports owner realtime is offline (silent reconnect otherwise).
class ReportsListRealtimeBanner extends ConsumerWidget {
  const ReportsListRealtimeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ReportsRealtimeService svc = ref.read(reportsRealtimeServiceProvider);
    return ValueListenableBuilder<ReportsRealtimeConnectionState?>(
      valueListenable: svc.connectionState,
      builder:
          (
            BuildContext context,
            ReportsRealtimeConnectionState? value,
            Widget? _,
          ) {
            final ReportsRealtimeConnectionState s =
                value ?? ReportsRealtimeConnectionState.live;
            if (s != ReportsRealtimeConnectionState.offline) {
              return const SizedBox.shrink();
            }
            return _BannerBody(
              message: l10n.connectionOfflineBanner,
              offline: true,
              tryAgainLabel: l10n.commonTryAgain,
              onTryAgain: () {
                ref.read(reportsRealtimeServiceProvider).requestReconnect();
              },
            );
          },
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({
    required this.message,
    required this.offline,
    this.tryAgainLabel,
    this.onTryAgain,
  });

  final String message;
  final bool offline;
  final String? tryAgainLabel;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Semantics(
        liveRegion: true,
        container: true,
        label: message,
        child: Material(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: AppRadii.sm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      offline ? Icons.cloud_off_outlined : Icons.sync,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 4,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypographySurfaces.reportsOutboxBannerBody(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ),
                  ],
                ),
                if (offline &&
                    onTryAgain != null &&
                    tryAgainLabel != null) ...<Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton.text(
                      label: tryAgainLabel!,
                      onPressed: onTryAgain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
