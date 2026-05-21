import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/safety/data/ugc_moderation_repository.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_text_field.dart';
import 'package:chisto_mobile/shared/widgets/atoms/primary_button.dart';
import 'package:flutter/material.dart';

/// Bottom sheet to report UGC (comment, chat message, user, etc.).
Future<bool?> showUgcReportSheet(
  BuildContext context, {
  required String subjectType,
  required String subjectId,
  String? title,
  UgcModerationRepository? repository,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
    ),
    builder: (BuildContext ctx) => _UgcReportSheetBody(
      subjectType: subjectType,
      subjectId: subjectId,
      title: title,
      repository: repository ?? UgcModerationRepository(),
    ),
  );
}

/// Typography for [showUgcReportSheet] — aligned with other profile/report sheets.
abstract final class UgcReportSheetTypography {
  static TextStyle get title => AppTypography.sheetTitle;

  static TextStyle get reasonLabel => AppTypography.textTheme.bodyLarge!.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
      );
}

class _UgcReportSheetBody extends StatefulWidget {
  const _UgcReportSheetBody({
    required this.subjectType,
    required this.subjectId,
    this.title,
    required this.repository,
  });

  final String subjectType;
  final String subjectId;
  final String? title;
  final UgcModerationRepository repository;

  @override
  State<_UgcReportSheetBody> createState() => _UgcReportSheetBodyState();
}

class _UgcReportSheetBodyState extends State<_UgcReportSheetBody> {
  String _reason = 'spam';
  bool _submitting = false;
  final TextEditingController _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.repository.submitReport(
        subjectType: widget.subjectType,
        subjectId: widget.subjectId,
        reason: _reason,
        details: _details.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppSnack.show(
        context,
        message: context.l10n.safetyReportSubmitted,
        type: AppSnackType.success,
      );
    } on Object {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.safetyReportFailed,
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.34),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            Text(
              widget.title ?? l10n.safetyReportTitle,
              style: UgcReportSheetTypography.title,
            ),
            const SizedBox(height: AppSpacing.md),
            ...<String>['spam', 'harassment', 'hate', 'violence', 'nudity', 'other'].map(
              (String value) => RadioListTile<String>(
                value: value,
                groupValue: _reason,
                onChanged: _submitting ? null : (String? v) => setState(() => _reason = v!),
                title: Text(
                  _reasonLabel(l10n, value),
                  style: UgcReportSheetTypography.reasonLabel,
                ),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                activeColor: AppColors.primaryDark,
              ),
            ),
            AppTextField(
              controller: _details,
              hintText: l10n.safetyReportDetailsHint,
              maxLines: 3,
              minLines: 3,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: l10n.safetyReportSubmit,
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }

  String _reasonLabel(dynamic l10n, String value) {
    switch (value) {
      case 'harassment':
        return l10n.safetyReportReasonHarassment;
      case 'hate':
        return l10n.safetyReportReasonHate;
      case 'violence':
        return l10n.safetyReportReasonViolence;
      case 'nudity':
        return l10n.safetyReportReasonNudity;
      case 'other':
        return l10n.safetyReportReasonOther;
      default:
        return l10n.safetyReportReasonSpam;
    }
  }
}
