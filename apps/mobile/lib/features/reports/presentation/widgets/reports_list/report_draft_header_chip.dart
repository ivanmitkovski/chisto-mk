import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_draft_saved_label.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';

/// Compact draft affordance in the reports list pinned header.
class ReportDraftHeaderChip extends StatelessWidget {
  const ReportDraftHeaderChip({
    super.key,
    required this.l10n,
    required this.onOpenDraft,

    /// Inline metrics row: no extra top inset (parent handles spacing).
    this.compact = false,
  });

  final AppLocalizations l10n;
  final VoidCallback onOpenDraft;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReportDraftSummary>(
      valueListenable:
          ServiceLocator.instance.reportDraftRepository.summaryListenable,
      builder: (BuildContext context, ReportDraftSummary s, _) {
        if (!s.hasDraft) {
          return const SizedBox.shrink();
        }
        final String savedAgo = reportDraftSavedIndicator(
          l10n,
          s.lastPersistedAtMs,
        );
        return Padding(
          padding: EdgeInsets.only(top: compact ? 0 : AppSpacing.xxs),
          child: Semantics(
            button: true,
            label: l10n.reportListDraftChipSemantic(s.photoCount),
            child: Material(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                onTap: () {
                  AppHaptics.tap();
                  chistoReportsBreadcrumb(
                    'report_draft',
                    'entry_reports_list_chip',
                  );
                  onOpenDraft();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    l10n.reportListDraftChipLabel(s.photoCount, savedAgo),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
