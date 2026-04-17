import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.event,
    this.embeddedInGroupedPanel = false,
  });

  final EcoEvent event;

  /// When true, uses inset row styling and a trailing chevron (use inside [EventDetailGroupedPanel]).
  final bool embeddedInGroupedPanel;

  void _showCategoryInfo(BuildContext context) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.eventsCategorySheetTitle,
          subtitle: event.category.localizedLabel(ctx.l10n),
          fitToContent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  event.category.icon,
                  size: 28,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                event.category.localizedDescription(ctx.l10n),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
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
    return Semantics(
      button: true,
      label: context.l10n.eventsCategorySemantic(
        event.category.localizedLabel(context.l10n),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showCategoryInfo(context),
          borderRadius: BorderRadius.circular(
            embeddedInGroupedPanel ? AppSpacing.radiusLg : AppSpacing.radius10,
          ),
          child: embeddedInGroupedPanel
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        event.category.icon,
                        size: AppSpacing.iconMd,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          event.category.localizedLabel(context.l10n),
                          style: AppTypography.eventsGroupedRowPrimary(
                            Theme.of(context).textTheme,
                          ),
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxs,
                    horizontal: AppSpacing.xxs / 2,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        event.category.icon,
                        size: AppSpacing.iconMd,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          event.category.localizedLabel(context.l10n),
                          style: AppTypography.eventsBodyMediumSecondary(
                            Theme.of(context).textTheme,
                          ),
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.info_circle,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
