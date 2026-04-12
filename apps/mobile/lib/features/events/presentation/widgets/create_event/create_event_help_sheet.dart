import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_modal_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

void showCreateEventHelpSheet(BuildContext context) {
  showCreateEventModalBottomSheet<void>(
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
        maxHeightFactor: 0.72,
        addBottomInset: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            _HelpBullet(
              text: ctx.l10n.createEventHelpBulletModeration,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.md),
            _HelpBullet(
              text: ctx.l10n.createEventHelpBulletVolunteers,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.md),
            _HelpBullet(
              text: ctx.l10n.createEventHelpBulletSite,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.md),
            _HelpBullet(
              text: ctx.l10n.createEventHelpBulletSchedule,
              textTheme: textTheme,
            ),
            const SizedBox(height: AppSpacing.md),
            _HelpBullet(
              text: ctx.l10n.createEventHelpBulletSubmit,
              textTheme: textTheme,
            ),
          ],
        ),
      );
    },
  );
}

class _HelpBullet extends StatelessWidget {
  const _HelpBullet({
    required this.text,
    required this.textTheme,
  });

  final String text;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            CupertinoIcons.circle_fill,
            size: 8,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}
