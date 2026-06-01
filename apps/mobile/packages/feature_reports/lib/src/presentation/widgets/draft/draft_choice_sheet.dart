import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/data/outbox/report_draft_repository.dart';
import 'package:feature_reports/src/presentation/l10n/report_draft_saved_label.dart';
import 'package:flutter/material.dart';

/// Result of the draft-choice sheet (central FAB or reports entry) when a saved draft exists.
enum CentralFabDraftChoice { continueDraft, takeNewPhoto, cancel }

Future<CentralFabDraftChoice> showCentralFabDraftChoiceSheet({
  required BuildContext context,
  required ReportDraftSummary summary,
}) async {
  final AppLocalizations l10n = context.l10n;
  final String savedAgo = reportDraftSavedIndicator(
    l10n,
    summary.lastPersistedAtMs,
  );
  chistoReportsBreadcrumb('report_draft', 'central_fab_sheet_shown');
  final CentralFabDraftChoice?
  choice = await showAppPanelBottomSheet<CentralFabDraftChoice>(
    context: context,
    // Root overlay so the sheet covers the home shell bottom bar + FAB when the
    // caller context is under the tab branch navigator (e.g. Reports list +).
    useRootNavigator: true,
    builder: (BuildContext ctx) {
      const TextTheme textTheme = AppTypography.textTheme;
      final TextStyle? subtitleStyle = textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        height: 1.45,
      );
      return AppSheetScaffold(
        title: l10n.reportDraftCentralFabSheetTitle,
        subtitle: l10n.reportDraftCentralFabSubtitle(
          summary.photoCount,
          savedAgo,
        ),
        useModalRouteShape: true,
        subtitleTextStyle: subtitleStyle,
        trailing: AppCircleIconButton(
          icon: Icons.close_rounded,
          semanticLabel: l10n.commonClose,
          onTap: () => Navigator.of(ctx).pop(CentralFabDraftChoice.cancel),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.sm),
            AppButton.primary(
              label: l10n.reportDraftCentralFabContinue,
              onPressed: () {
                chistoReportsBreadcrumb(
                  'report_draft',
                  'entry_central_fab_continue',
                );
                Navigator.of(ctx).pop(CentralFabDraftChoice.continueDraft);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.outlined(
              label: l10n.reportDraftCentralFabTakeNewPhoto,
              onPressed: () {
                chistoReportsBreadcrumb(
                  'report_draft',
                  'entry_central_fab_take_new',
                );
                Navigator.of(ctx).pop(CentralFabDraftChoice.takeNewPhoto);
              },
              expand: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton.text(
              label: l10n.reportDraftCentralFabCancel,
              onPressed: () {
                chistoReportsBreadcrumb(
                  'report_draft',
                  'entry_central_fab_cancel',
                );
                Navigator.of(ctx).pop(CentralFabDraftChoice.cancel);
              },
            ),
          ],
        ),
      );
    },
  );
  return choice ?? CentralFabDraftChoice.cancel;
}
