import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';

class OrganizerSection extends StatelessWidget {
  const OrganizerSection({super.key, required this.event});

  final EcoEvent event;

  void _showOrganizerInfo(BuildContext context) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.eventsOrganizerSheetTitle,
          subtitle: event.organizerName,
          fitToContent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UserAvatarCircle(
                displayName: event.organizerName,
                imageUrl: event.organizerAvatarUrl,
                size: 64,
                seed: event.organizerId,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                event.isOrganizer
                    ? ctx.l10n.eventsOrganizerYouOwnThis
                    : ctx.l10n.eventsOrganizerRoleLabel,
                style: AppTypography.eventsBodyMuted(Theme.of(ctx).textTheme),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radius14),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        ctx.l10n.eventsOrganizerCreatedOn(
                          event.createdAt.day,
                          event.createdAt.month,
                          event.createdAt.year,
                        ),
                        style: AppTypography.eventsGridPropertyValue(
                          Theme.of(ctx).textTheme,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: context.l10n.eventsOrganizerSemantic(event.organizerName),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showOrganizerInfo(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                UserAvatarCircle(
                  displayName: event.organizerName,
                  imageUrl: event.organizerAvatarUrl,
                  size: 40,
                  seed: event.organizerId,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.eventsOrganizedByLabel,
                        style: AppTypography.eventsListCardMeta(textTheme),
                      ),
                      Text(
                        event.organizerName,
                        style: AppTypography.eventsGroupedRowPrimary(textTheme),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
