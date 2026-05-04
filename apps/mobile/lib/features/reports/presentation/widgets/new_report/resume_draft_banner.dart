import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_modal_dialog.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// User chose to keep the restored draft from the resume prompt.
enum ResumeDraftBannerResult { continued, discarded }

String _formatReportDraftSavedTimestamp(AppLocalizations l10n, int millis) {
  final DateTime d = DateTime.fromMillisecondsSinceEpoch(millis);
  return DateFormat.yMMMd(l10n.localeName).add_jm().format(d);
}

/// Blocking dialog: continue editing the restored draft or discard it (with confirm).
Future<ResumeDraftBannerResult?> showResumeDraftBanner({
  required BuildContext context,
  required AppLocalizations l10n,
  required ReportDraftLoadResult loadResult,
}) async {
  final ReportOutboxEntry? row = loadResult.row;
  if (row == null) {
    return ResumeDraftBannerResult.continued;
  }
  chistoReportsBreadcrumb(
    'report_draft',
    'resume_banner_shown',
    data: <String, Object?>{
      'photoCount': row.draft.photos.length,
      'hasTitle':
          row.title.trim().isNotEmpty || row.draft.title.trim().isNotEmpty,
    },
  );

  final TextStyle? bodyStyle = AppTypography.textTheme.bodyMedium?.copyWith(
    color: AppColors.textSecondary,
    height: 1.45,
  );

  while (context.mounted) {
    final String? action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (BuildContext ctx) {
        final String titlePreviewRaw =
            row.title.trim().isNotEmpty ? row.title : row.draft.title;
        final String titlePreview =
            titlePreviewRaw.trim().isEmpty ? '—' : titlePreviewRaw.trim();
        final int savedAt = row.lastPersistedAtMs ?? row.updatedAtMs;
        return ReportModalDialog(
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(
                Icons.edit_note_rounded,
                size: 28,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          title: l10n.reportDraftResumeTitle,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PrimaryButton(
                label: l10n.reportDraftResumeContinue,
                onPressed: () {
                  AppHaptics.light();
                  Navigator.of(ctx).pop('continue');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(ctx).pop('discard');
                },
                child: Text(
                  l10n.reportDraftResumeDiscard,
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Text(
              l10n.reportDraftResumeBody(
                row.draft.photos.length,
                titlePreview,
                _formatReportDraftSavedTimestamp(l10n, savedAt),
              ),
              style: bodyStyle,
            ),
          ),
        );
      },
    );

    if (!context.mounted) {
      return null;
    }

    if (action == 'continue') {
      chistoReportsBreadcrumb('report_draft', 'resume_banner_continue');
      return ResumeDraftBannerResult.continued;
    }

    if (action == 'discard') {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierColor: AppColors.black.withValues(alpha: 0.45),
        builder: (BuildContext ctx) {
          return ReportModalDialog(
            title: l10n.reportDraftDiscardConfirmTitle,
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    AppHaptics.tap();
                    Navigator.of(ctx).pop(false);
                  },
                  child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentDanger,
                  ),
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(l10n.reportDraftResumeDiscard),
                ),
              ],
            ),
            child: Text(
              l10n.reportDraftDiscardConfirmBody,
              style: bodyStyle,
            ),
          );
        },
      );
      if (!context.mounted) {
        return null;
      }
      if (confirmed == true) {
        chistoReportsBreadcrumb('report_draft', 'resume_banner_discard');
        return ResumeDraftBannerResult.discarded;
      }
      continue;
    }

    return ResumeDraftBannerResult.continued;
  }
  return null;
}
