import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_draft_saved_label.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_modal_dialog.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';

/// User decision when opening the wizard with a new photo while a draft exists.
enum ResumeWithIncomingChoice { continueDraft, replaceDraft, addPhoto }

Future<ResumeWithIncomingChoice?> showResumeWithIncomingPhotoDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required ReportDraftSummary summary,
}) async {
  final String savedAgo = reportDraftSavedIndicator(l10n, summary.lastPersistedAtMs);
  chistoReportsBreadcrumb('report_draft', 'incoming_photo_dialog_shown');
  final TextStyle? bodyStyle = AppTypography.textTheme.bodyMedium?.copyWith(
    color: AppColors.textSecondary,
    height: 1.45,
  );
  return showDialog<ResumeWithIncomingChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.black.withValues(alpha: 0.45),
    builder: (BuildContext ctx) {
      return ReportModalDialog(
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 28,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        title: l10n.reportDraftIncomingPhotoTitle,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PrimaryButton(
              label: l10n.reportDraftIncomingPhotoContinue,
              onPressed: () {
                AppHaptics.light();
                Navigator.of(ctx).pop(ResumeWithIncomingChoice.continueDraft);
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
                  Navigator.of(ctx).pop(ResumeWithIncomingChoice.replaceDraft);
                },
                child: Text(
                  l10n.reportDraftIncomingPhotoReplace,
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                  Navigator.of(ctx).pop(ResumeWithIncomingChoice.addPhoto);
                },
                child: Text(
                  l10n.reportDraftIncomingPhotoAdd,
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Text(
            l10n.reportDraftIncomingPhotoBody(summary.photoCount, savedAgo),
            style: bodyStyle,
          ),
        ),
      );
    },
  );
}
