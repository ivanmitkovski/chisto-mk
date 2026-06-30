import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:flutter/material.dart';

/// Profile: credits title, pill (number-only when healthy), and
/// [ReportInfoBanner] for low, emergency, and cooldown.
class ReportCapacitySummaryCard extends StatelessWidget {
  const ReportCapacitySummaryCard({required this.capacity, super.key});

  final ReportCapacity capacity;

  @override
  Widget build(BuildContext context) {
    final String? nextLabel = formatNextEmergencyUnlockLocal(
      context,
      capacity.nextEmergencyReportAvailableAt,
    );
    final AppLocalizations l10n = context.l10n;
    final ReportCapacityUiState ui = mapReportCapacityToUiState(
      capacity,
      l10n: l10n,
      nextEmergencyAvailableDescription: nextLabel,
    );
    final bool showSecondsSuffix =
        ui.kind == ReportCapacityUiKind.cooldown &&
        nextLabel == null &&
        capacity.retryAfterSeconds != null &&
        capacity.retryAfterSeconds! > 0;
    final String subtitle = showSecondsSuffix
        ? '${ui.bannerMessage} ${l10n.reportCapacitySecondsRemaining(capacity.retryAfterSeconds!)}'
        : ui.bannerMessage;

    final bool healthyCompact = ui.kind == ReportCapacityUiKind.healthy;
    final int credits = capacity.creditsAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.profileReportCreditsTitle,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (healthyCompact)
                Semantics(
                  label: ui.pillLabel,
                  child: ReportStatePill(label: '$credits', tone: ui.pillTone),
                )
              else
                ReportStatePill(
                  label: ui.pillLabel,
                  tone: ui.pillTone,
                  icon: ui.pillIcon,
                ),
            ],
          ),
          if (!healthyCompact) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ReportInfoBanner(
              title: ui.bannerTitle,
              message: subtitle,
              icon: ui.bannerIcon,
              tone: ui.bannerTone,
            ),
          ],
        ],
      ),
    );
  }
}
