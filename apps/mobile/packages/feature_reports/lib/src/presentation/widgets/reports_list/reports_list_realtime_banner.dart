import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows when [ReportsRealtimeConnectionState.offline] — e.g. auth refresh failed or
/// transport could not connect. Hides automatically when the socket reaches [live]
/// again (including after connectivity returns; see [ReportsOwnerSocketStream]).
class ReportsListRealtimeBanner extends ConsumerWidget {
  const ReportsListRealtimeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return ValueListenableBuilder<ReportsRealtimeConnectionState?>(
      valueListenable: ref.read(reportsRealtimeServiceProvider).connectionState,
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
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Material(
                color: AppColors.primary.withValues(alpha: 0.12),
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
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.reportsSseOfflineBanner,
                              maxLines: 4,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    height: 1.35,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppButton.text(
                          label: l10n.reportsSseReconnectAction,
                          onPressed: () {
                            ref
                                .read(reportsRealtimeServiceProvider)
                                .requestReconnect();
                          },
                        ),
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
