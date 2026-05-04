import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:flutter/material.dart';

EdgeInsets newReportDetailsFieldScrollPadding(BuildContext context) {
  final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
  return EdgeInsets.only(bottom: safeBottom + AppSpacing.lg);
}

class NewReportDetailsTitleField extends StatelessWidget {
  const NewReportDetailsTitleField({
    super.key,
    required this.draft,
    required this.attemptedStages,
    required this.titleController,
    required this.titleFocus,
    required this.maxTitleLength,
    required this.onTitleChanged,
  });

  final ReportDraft draft;
  final Set<ReportStage> attemptedStages;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final int maxTitleLength;
  final ValueChanged<String> onTitleChanged;

  @override
  Widget build(BuildContext context) {
    final bool hasTitleError =
        attemptedStages.contains(ReportStage.details) && !draft.hasTitle;
    final int length = titleController.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              context.l10n.reportReviewTitleLabel,
              style: AppTypography.reportsFormFieldLabel(
                Theme.of(context).textTheme,
                color: hasTitleError
                    ? AppColors.accentDanger
                    : AppColors.textSecondary,
              ),
            ),
            Text(
              '$length/$maxTitleLength',
              style: AppTypography.reportsCharCounter(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: titleController,
          focusNode: titleFocus,
          scrollPadding: newReportDetailsFieldScrollPadding(context),
          maxLength: maxTitleLength,
          maxLines: 1,
          textCapitalization: TextCapitalization.sentences,
          onChanged: onTitleChanged,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.reportReviewTitleHint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.15,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            counterText: '',
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: hasTitleError
                    ? AppColors.accentDanger
                    : AppColors.divider,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NewReportDetailsDescriptionField extends StatelessWidget {
  const NewReportDetailsDescriptionField({
    super.key,
    required this.descriptionController,
    required this.descriptionFocus,
    required this.maxDescriptionLength,
    required this.onDescriptionChanged,
  });

  final TextEditingController descriptionController;
  final FocusNode descriptionFocus;
  final int maxDescriptionLength;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final int length = descriptionController.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              context.l10n.reportStageDetailsTitle,
              style: AppTypography.reportsFormFieldLabel(
                Theme.of(context).textTheme,
              ),
            ),
            Text(
              '$length/$maxDescriptionLength',
              style: AppTypography.reportsCharCounter(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: descriptionController,
          focusNode: descriptionFocus,
          scrollPadding: newReportDetailsFieldScrollPadding(context),
          maxLength: maxDescriptionLength,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onChanged: onDescriptionChanged,
          textInputAction: TextInputAction.done,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.reportDescriptionHint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.15,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            counterText: '',
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
