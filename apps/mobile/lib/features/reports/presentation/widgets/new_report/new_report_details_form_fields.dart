import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_details_category_severity_fields.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_details_cleanup_field.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/new_report_details_text_fields.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:flutter/material.dart';

/// Details step: category, severity, title, description, cleanup effort.
class NewReportDetailsFormFields extends StatelessWidget {
  const NewReportDetailsFormFields({
    super.key,
    required this.draft,
    required this.attemptedStages,
    required this.titleController,
    required this.descriptionController,
    required this.titleFocus,
    required this.descriptionFocus,
    required this.maxTitleLength,
    required this.maxDescriptionLength,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onSeverityChanged,
    required this.onCategorySelected,
    required this.onCleanupEffort,
  });

  final ReportDraft draft;
  final Set<ReportStage> attemptedStages;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final FocusNode titleFocus;
  final FocusNode descriptionFocus;
  final int maxTitleLength;
  final int maxDescriptionLength;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<int> onSeverityChanged;
  final ValueChanged<ReportCategory> onCategorySelected;
  final ValueChanged<CleanupEffort> onCleanupEffort;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        NewReportDetailsCategoryField(
          draft: draft,
          attemptedStages: attemptedStages,
          onCategorySelected: onCategorySelected,
        ),
        const SizedBox(height: AppSpacing.md),
        NewReportDetailsSeverityField(
          draft: draft,
          onSeverityChanged: onSeverityChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        NewReportDetailsTitleField(
          draft: draft,
          attemptedStages: attemptedStages,
          titleController: titleController,
          titleFocus: titleFocus,
          maxTitleLength: maxTitleLength,
          onTitleChanged: onTitleChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        NewReportDetailsDescriptionField(
          descriptionController: descriptionController,
          descriptionFocus: descriptionFocus,
          maxDescriptionLength: maxDescriptionLength,
          onDescriptionChanged: onDescriptionChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        NewReportDetailsCleanupEffortField(
          draft: draft,
          onCleanupEffort: onCleanupEffort,
        ),
      ],
    );
  }
}
