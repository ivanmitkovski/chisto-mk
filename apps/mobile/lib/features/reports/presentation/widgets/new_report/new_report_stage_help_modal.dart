import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_config.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage_help.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';

/// Bottom sheet with localized help for a report wizard step.
Future<void> showNewReportStageHelpModal(
  BuildContext context,
  ReportStage stage, {
  required Future<void> Function() onFlowHelpOpened,
  String? infoExtra,
}) async {
  AppHaptics.light();
  await onFlowHelpOpened();
  if (!context.mounted) return;
  final String trimmed = infoExtra?.trim() ?? '';
  final String barrierLabel = MaterialLocalizations.of(
    context,
  ).modalBarrierDismissLabel;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: AppColors.transparent,
    elevation: 0,
    barrierLabel: barrierLabel,
    builder: (BuildContext sheetContext) {
      final ReportStageConfig cfg = stage.config(sheetContext.l10n);
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: MediaQuery.sizeOf(sheetContext).width,
            child: ReportSheetScaffold(
              fitToContent: true,
              addBottomInset: true,
              maxHeightFactor: 0.92,
              headerDividerGap: AppSpacing.sm,
              title: cfg.infoTitle,
              subtitle: cfg.subtitle,
              trailing: ReportCircleIconButton(
                icon: Icons.close_rounded,
                semanticLabel: sheetContext.l10n.semanticsClose,
                onTap: () {
                  AppHaptics.tap();
                  Navigator.of(sheetContext).pop();
                },
              ),
              child: StageHelpFormattedContent(
                sections: cfg.helpSections,
                contextSectionTitle: sheetContext.l10n.reportHelpContextTitle,
                extraParagraph: trimmed.isEmpty ? null : trimmed,
              ),
            ),
          ),
        ),
      );
    },
  );
}
