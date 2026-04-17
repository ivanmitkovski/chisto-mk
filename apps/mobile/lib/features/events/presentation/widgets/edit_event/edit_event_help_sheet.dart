import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

/// Schedule-focused help for organizers editing an existing event.
void showEditEventHelpSheet(BuildContext context) {
  showEventsSurfaceModal<void>(
    context: context,
    builder: (BuildContext ctx) {
      final TextTheme textTheme = Theme.of(ctx).textTheme;
      return ReportSheetScaffold(
        title: ctx.l10n.editEventHelpTitle,
        subtitle: ctx.l10n.editEventHelpSubtitle,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: ctx.l10n.commonClose,
          onTap: () => Navigator.of(ctx).pop(),
        ),
        fitToContent: true,
        maxHeightFactor: 0.94,
        addBottomInset: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _EditHelpRow(
                icon: Icons.event_outlined,
                text: ctx.l10n.createEventHelpBulletSchedule,
                textTheme: textTheme,
              ),
              _EditHelpRow(
                icon: Icons.groups_2_outlined,
                text: ctx.l10n.createEventHelpBulletVolunteers,
                textTheme: textTheme,
              ),
              _EditHelpRow(
                icon: Icons.verified_outlined,
                text: ctx.l10n.createEventHelpBulletModeration,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EditHelpRow extends StatelessWidget {
  const _EditHelpRow({
    required this.icon,
    required this.text,
    required this.textTheme,
  });

  final IconData icon;
  final String text;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.inputFill.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    text,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
