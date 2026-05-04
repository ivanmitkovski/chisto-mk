import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_draft_saved_label.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
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
  final CentralFabDraftChoice? choice =
      await showModalBottomSheet<CentralFabDraftChoice>(
    context: context,
    isScrollControlled: true,
    // Root overlay so the sheet covers the home shell bottom bar + FAB when the
    // caller context is under the tab branch navigator (e.g. Reports list +).
    useRootNavigator: true,
    // Match other shell-level sheets: avoid removeTop quirks; content still gets
    // bottom inset for the home indicator.
    useSafeArea: true,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    elevation: 0,
    builder: (BuildContext ctx) {
      final TextTheme textTheme = AppTypography.textTheme;
      final TextStyle? subtitleStyle = textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        height: 1.45,
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.reportDraftCentralFabSheetTitle,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.reportDraftCentralFabSubtitle(summary.photoCount, savedAgo),
              style: subtitleStyle,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.reportDraftCentralFabContinue,
              onPressed: () {
                AppHaptics.light();
                chistoReportsBreadcrumb(
                  'report_draft',
                  'entry_central_fab_continue',
                );
                Navigator.of(ctx).pop(CentralFabDraftChoice.continueDraft);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.inputBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                onPressed: () {
                  AppHaptics.tap();
                  chistoReportsBreadcrumb(
                    'report_draft',
                    'entry_central_fab_take_new',
                  );
                  Navigator.of(ctx).pop(CentralFabDraftChoice.takeNewPhoto);
                },
                child: Text(
                  l10n.reportDraftCentralFabTakeNewPhoto,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              onPressed: () {
                AppHaptics.tap();
                chistoReportsBreadcrumb(
                  'report_draft',
                  'entry_central_fab_cancel',
                );
                Navigator.of(ctx).pop(CentralFabDraftChoice.cancel);
              },
              child: Text(
                l10n.reportDraftCentralFabCancel,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  return choice ?? CentralFabDraftChoice.cancel;
}
