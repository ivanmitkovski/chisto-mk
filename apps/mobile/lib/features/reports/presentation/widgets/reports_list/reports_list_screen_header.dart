import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_status_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_draft_header_chip.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_filter_chip.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Title row + total / under-review / capacity pills for the reports list pinned header.
class ReportsListStatsHeader extends StatelessWidget {
  const ReportsListStatsHeader({
    super.key,
    required this.totalReports,
    required this.underReviewCount,
    required this.reportCapacity,
    required this.l10n,
    required this.onStartNewReport,
  });

  final int totalReports;
  final int underReviewCount;
  final ReportCapacity? reportCapacity;
  final AppLocalizations l10n;
  final VoidCallback onStartNewReport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.reportListHeaderTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.reportListAppBarStartNewReportLabel,
                child: IconButton(
                  tooltip: l10n.reportListAppBarStartNewReportLabel,
                  onPressed: () {
                    AppHaptics.tap();
                    chistoReportsBreadcrumb(
                      'report_draft',
                      'entry_reports_list_appbar_plus',
                    );
                    onStartNewReport();
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<ReportDraftSummary>(
            valueListenable:
                ServiceLocator.instance.reportDraftRepository.summaryListenable,
            builder: (BuildContext context, ReportDraftSummary summary, _) {
              if (!summary.hasDraft) {
                return const SizedBox(height: AppSpacing.sm);
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ReportDraftHeaderChip(
                      l10n: l10n,
                      onOpenDraft: onStartNewReport,
                      compact: false,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              );
            },
          ),
          Semantics(
            liveRegion: true,
            label: l10n.reportListHeaderSemanticSummary(
              totalReports,
              underReviewCount,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double gap = constraints.maxWidth >= 400
                    ? AppSpacing.md
                    : AppSpacing.sm;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ReportStatePill(
                        label: l10n.reportListHeaderTotalPill(totalReports),
                        icon: Icons.description_outlined,
                      ),
                      SizedBox(width: gap),
                      ReportStatePill(
                        label: l10n.reportListHeaderUnderReviewPill(
                          underReviewCount,
                        ),
                        icon: Icons.schedule_rounded,
                        tone: underReviewCount > 0
                            ? ReportSurfaceTone.warning
                            : ReportSurfaceTone.neutral,
                      ),
                      if (reportCapacity != null) ...<Widget>[
                        SizedBox(width: gap),
                        Builder(
                          builder: (BuildContext context) {
                            final ReportCapacityUiState ui =
                                mapReportCapacityToUiState(
                                  reportCapacity!,
                                  l10n: l10n,
                                  nextEmergencyAvailableDescription:
                                      formatNextEmergencyUnlockLocal(
                                        context,
                                        reportCapacity!
                                            .nextEmergencyReportAvailableAt,
                                      ),
                                );
                            return ReportStatePill(
                              label: ui.pillLabel,
                              icon: ui.pillIcon,
                              tone: ui.pillTone,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Search field for the reports list pinned header.
class ReportsListSearchBar extends StatelessWidget {
  const ReportsListSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.resultSummaryLabel,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String resultSummaryLabel;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String hint = '${l10n.reportListSearchHintPrefix} $resultSummaryLabel'
        .trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Semantics(
        label: l10n.reportListSearchSemantic,
        hint: hint,
        child: TapRegion(
          onTapOutside: (PointerDownEvent _) {
            // Dismiss keyboard when tapping outside the field (TapRegionSurface is
            // provided by MaterialApp / CupertinoApp under the full screen).
            focusNode.unfocus();
          },
          child: CupertinoSearchTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: l10n.reportListSearchPlaceholder,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            placeholderStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.radius10,
            ),
            backgroundColor: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onSubmitted: (_) => onSubmitted(),
            onSuffixTap: () {
              AppHaptics.tap();
              onClear();
            },
          ),
        ),
      ),
    );
  }
}

/// Horizontal status filter chips for the reports list pinned header.
class ReportsListStatusFilterBar extends StatelessWidget {
  const ReportsListStatusFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ReportSheetStatus? selected;
  final ValueChanged<ReportSheetStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<ReportSheetStatus?> filters = <ReportSheetStatus?>[
      null,
      ...ReportSheetStatus.values,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            for (final ReportSheetStatus? status in filters) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ReportFilterChip(
                  label: status == null
                      ? l10n.reportListFilterAll
                      : reportUiStatusShortLabel(l10n, status),
                  selected: selected == status,
                  onTap: () => onSelected(status),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
