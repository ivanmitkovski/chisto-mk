import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_category_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/cupertino.dart';

/// Modal picker for report category with icons.
void showReportCategoryPicker(
  BuildContext context, {
  required ReportCategory? selected,
  required void Function(ReportCategory) onSelected,
}) {
  AppHaptics.tap();
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) {
      final AppLocalizations l10n = context.l10n;
      return ReportSheetScaffold(
        title: l10n.reportCategoryPickerTitle,
        subtitle: l10n.reportCategoryPickerSubtitle,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: l10n.semanticsClose,
          onTap: () => Navigator.of(context).pop(),
        ),
        maxHeightFactor: 0.78,
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            ReportInfoBanner(
              title: l10n.reportCategoryPickerBannerTitle,
              message: l10n.reportCategoryPickerBannerBody,
              icon: CupertinoIcons.square_list,
            ),
            const SizedBox(height: AppSpacing.md),
            ...ReportCategory.values.expand((ReportCategory cat) {
              final bool isActive = cat == selected;
              return <Widget>[
                ReportActionTile(
                  icon: cat.icon,
                  title: cat.localizedTitle(l10n),
                  subtitle: cat.localizedDescription(l10n),
                  tone: isActive
                      ? ReportSurfaceTone.accent
                      : ReportSurfaceTone.neutral,
                  trailing: Icon(
                    isActive
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 22,
                    color: isActive ? AppColors.primaryDark : AppColors.divider,
                  ),
                  onTap: () {
                    AppHaptics.tap();
                    onSelected(cat);
                    Navigator.of(context).pop();
                  },
                ),
                if (cat != ReportCategory.values.last)
                  const SizedBox(height: AppSpacing.sm),
              ];
            }),
          ],
        ),
      );
    },
  );
}
