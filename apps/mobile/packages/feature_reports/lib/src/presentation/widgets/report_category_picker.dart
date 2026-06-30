import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/presentation/l10n/report_category_l10n.dart';
import 'package:flutter/material.dart';

/// Modal picker for report category with icons.
void showReportCategoryPicker(
  BuildContext context, {
  required ReportCategory? selected,
  required void Function(ReportCategory) onSelected,
}) {
  final AppLocalizations l10n = context.l10n;
  showAppGroupedOptionPicker<ReportCategory>(
    context: context,
    title: l10n.reportCategoryPickerTitle,
    subtitle: l10n.reportCategoryPickerSubtitle,
    closeSemanticLabel: l10n.semanticsClose,
    options: ReportCategory.values
        .map(
          (ReportCategory cat) => AppGroupedOption<ReportCategory>(
            icon: cat.icon,
            title: cat.localizedTitle(l10n),
            subtitle: cat.localizedDescription(l10n),
            value: cat,
            semanticsLabel: cat.localizedTitle(l10n),
          ),
        )
        .toList(growable: false),
    isSelected: (ReportCategory cat) => cat == selected,
    onOptionTap: onSelected,
  );
}
