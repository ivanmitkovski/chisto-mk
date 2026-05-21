import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_grouped_panel.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_labels.dart';
import 'package:flutter/material.dart';

class SiteHistoryStatusHeader extends StatelessWidget {
  const SiteHistoryStatusHeader({
    super.key,
    required this.site,
    required this.entryCount,
    this.mostRecentEntryAt,
  });

  final PollutionSite site;
  final int entryCount;
  final DateTime? mostRecentEntryAt;

  @override
  Widget build(BuildContext context) {
    final String statusCode = mapStatusCodeFromUnknown(site.statusCode);
    final String statusLabel = mapStatusDisplay(context.l10n, statusCode);

    final DateTime? updatedAt = mostRecentEntryAt ?? site.latestReportAt;
    final String? updatedLabel = updatedAt != null
        ? context.l10n.siteHistoryStatusHeaderUpdated(
            siteHistoryRelativeTime(context, updatedAt),
          )
        : null;

    final String entriesLabel =
        context.l10n.siteHistoryStatusHeaderEntries(entryCount);

    final String semanticLabel = updatedLabel != null
        ? '${context.l10n.siteHistoryStatusHeaderTitle}: $statusLabel. '
            '$updatedLabel. $entriesLabel'
        : '${context.l10n.siteHistoryStatusHeaderTitle}: $statusLabel. '
            '$entriesLabel';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.siteHistoryStatusHeaderTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SiteHistoryGroupedPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (updatedLabel != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs / 2),
                          Text(
                            updatedLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entriesLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
