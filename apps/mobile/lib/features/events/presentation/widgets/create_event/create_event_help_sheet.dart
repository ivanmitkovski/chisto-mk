import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

void showCreateEventHelpSheet(BuildContext context) {
  showEventsSurfaceModal<void>(
    context: context,
    builder: (BuildContext ctx) {
      final TextTheme textTheme = Theme.of(ctx).textTheme;
      return ReportSheetScaffold(
        title: ctx.l10n.createEventHelpTitle,
        subtitle: ctx.l10n.createEventHelpSubtitle,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: ctx.l10n.commonClose,
          onTap: () => Navigator.of(ctx).pop(),
        ),
        // Fit sheet height to content; cap near full screen so tall text/locales scroll inside.
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
              _HelpInfoRow(
                icon: Icons.verified_outlined,
                text: ctx.l10n.createEventHelpBulletModeration,
                textTheme: textTheme,
              ),
              _HelpInfoRow(
                icon: Icons.groups_2_outlined,
                text: ctx.l10n.createEventHelpBulletVolunteers,
                textTheme: textTheme,
              ),
              _HelpInfoRow(
                icon: Icons.location_on_outlined,
                text: ctx.l10n.createEventHelpBulletSite,
                textTheme: textTheme,
              ),
              _HelpInfoRow(
                icon: Icons.event_outlined,
                text: ctx.l10n.createEventHelpBulletSchedule,
                textTheme: textTheme,
              ),
              _HelpInfoRow(
                icon: Icons.date_range_outlined,
                text: ctx.l10n.createEventHelpBulletSameDay,
                textTheme: textTheme,
              ),
              _HelpInfoRow(
                icon: Icons.publish_outlined,
                text: ctx.l10n.createEventHelpBulletSubmit,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Matches the visual language of [ShareActionTile] in share sheets (soft card + framed icon),
/// without tap affordances — informational only.
class _HelpInfoRow extends StatelessWidget {
  const _HelpInfoRow({
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
