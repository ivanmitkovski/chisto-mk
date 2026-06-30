import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_date_section_header.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_grouped_panel.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_labels.dart';
import 'package:flutter/material.dart';

class SiteHistoryStatusHeader extends StatelessWidget {
  const SiteHistoryStatusHeader({
    super.key,
    required this.site,
    this.summary,
    this.entryCount = 0,
    this.mostRecentEntryAt,
  });

  final PollutionSite site;
  final SiteHistorySummary? summary;
  final int entryCount;
  final DateTime? mostRecentEntryAt;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String statusCode = mapStatusCodeFromUnknown(
      summary?.currentStatus ?? site.statusCode,
    );
    final String statusLabel = mapStatusDisplay(context.l10n, statusCode);
    final Color statusColor = mapStatusColor(statusCode);

    final int resolvedEntryCount = summary?.totalEntries ?? entryCount;
    final int reportCount = summary?.reportCount ?? 0;
    final int cleanupCount = summary?.cleanupCount ?? 0;
    final DateTime? activeSince = summary?.firstActivityAt;
    final DateTime? updatedAt =
        summary?.lastActivityAt ?? mostRecentEntryAt ?? site.latestReportAt;

    final String? updatedLabel = updatedAt != null
        ? context.l10n.siteHistoryStatusHeaderUpdated(
            siteHistoryRelativeTime(context, updatedAt),
          )
        : null;

    final String entriesLabel = context.l10n.siteHistoryStatusHeaderEntries(
      resolvedEntryCount,
    );

    final String? activeSinceLabel = activeSince != null
        ? context.l10n.siteHistorySummaryActiveSince(
            siteHistoryAbsoluteDate(context, activeSince),
          )
        : null;

    final String semanticLabel = updatedLabel != null
        ? '${context.l10n.siteHistoryStatusHeaderTitle}: $statusLabel. '
              '$updatedLabel. $entriesLabel'
        : '${context.l10n.siteHistoryStatusHeaderTitle}: $statusLabel. '
              '$entriesLabel';

    final List<String> metaParts = <String>[
      if (activeSinceLabel != null) activeSinceLabel,
      if (updatedLabel != null) updatedLabel,
    ];

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SiteHistorySectionLabel(
            label: context.l10n.siteHistoryStatusHeaderTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          SiteHistoryGroupedPanel(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppStatusPill(
                    label: statusLabel,
                    color: statusColor,
                    dense: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      _HistoryStatChip(
                        icon: Icons.flag_outlined,
                        label: context.l10n.siteHistorySummaryReports(
                          reportCount,
                        ),
                        color: AppColors.notificationReport,
                      ),
                      _HistoryStatChip(
                        icon: Icons.cleaning_services_outlined,
                        label: context.l10n.siteHistorySummaryCleanups(
                          cleanupCount,
                        ),
                        color: AppColors.notificationChat,
                      ),
                      _HistoryStatChip(
                        icon: Icons.history_rounded,
                        label: entriesLabel,
                        color: statusColor,
                      ),
                    ],
                  ),
                  if (metaParts.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      metaParts.join(' · '),
                      style: AppTypographySurfaces.homeCleaningEventsMeta(
                        textTheme,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches the floating chips on [SiteStatsRow] in the pollution site tab.
class _HistoryStatChip extends StatelessWidget {
  const _HistoryStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: AppShadows.softCard(Theme.of(context).colorScheme),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.chipLabel(textTheme).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
