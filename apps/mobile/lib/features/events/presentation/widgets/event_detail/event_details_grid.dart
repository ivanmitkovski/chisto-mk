import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_grouped_panel.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EventDetailsGrid extends StatelessWidget {
  const EventDetailsGrid({
    super.key,
    required this.event,
    this.embeddedInGroupedPanel = false,
  });

  final EcoEvent event;

  /// When true, adds vertical inset for use inside [EventDetailGroupedPanel].
  final bool embeddedInGroupedPanel;

  static void _showInfoSheet(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: title,
          fitToContent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radius14),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.eventsBodyMuted(Theme.of(ctx).textTheme).copyWith(
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
    final bool hasScale = event.scale != null;
    final bool hasDifficulty = event.difficulty != null;

    if (!hasScale && !hasDifficulty) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = context.l10n;
    final Widget row = Row(
      children: <Widget>[
        if (hasScale)
          Expanded(
            child: DetailChip(
              icon: Icons.groups_rounded,
              label: event.scale!.localizedLabel(l10n),
              color: AppColors.primaryDark,
              onTap: () => _showInfoSheet(
                context,
                icon: Icons.groups_rounded,
                title: event.scale!.localizedLabel(l10n),
                description: event.scale!.localizedDescription(l10n),
                color: AppColors.primaryDark,
              ),
            ),
          ),
        if (hasScale && hasDifficulty)
          const SizedBox(width: AppSpacing.sm),
        if (hasDifficulty)
          Expanded(
            child: DetailChip(
              icon: CupertinoIcons.shield_fill,
              label: event.difficulty!.localizedLabel(l10n),
              color: event.difficulty!.color,
              onTap: () => _showInfoSheet(
                context,
                icon: CupertinoIcons.shield_fill,
                title: event.difficulty!.localizedLabel(l10n),
                description: event.difficulty!.localizedDescription(l10n),
                color: event.difficulty!.color,
              ),
            ),
          ),
      ],
    );

    if (embeddedInGroupedPanel) {
      final TextTheme textTheme = Theme.of(context).textTheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (hasScale)
            _GroupedPanelDetailsRow(
              icon: Icons.groups_outlined,
              label: event.scale!.localizedLabel(l10n),
              textTheme: textTheme,
              onTap: () => _showInfoSheet(
                context,
                icon: Icons.groups_rounded,
                title: event.scale!.localizedLabel(l10n),
                description: event.scale!.localizedDescription(l10n),
                color: AppColors.primaryDark,
              ),
            ),
          if (hasScale && hasDifficulty)
            Padding(
              padding: const EdgeInsets.only(
                left: EventDetailGroupedPanel.innerDividerLeadingPadding,
              ),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.divider.withValues(alpha: 0.7),
              ),
            ),
          if (hasDifficulty)
            _GroupedPanelDetailsRow(
              icon: Icons.shield_outlined,
              label: event.difficulty!.localizedLabel(l10n),
              textTheme: textTheme,
              onTap: () => _showInfoSheet(
                context,
                icon: CupertinoIcons.shield_fill,
                title: event.difficulty!.localizedLabel(l10n),
                description: event.difficulty!.localizedDescription(l10n),
                color: event.difficulty!.color,
              ),
            ),
        ],
      );
    }
    return row;
  }
}

class _GroupedPanelDetailsRow extends StatelessWidget {
  const _GroupedPanelDetailsRow({
    required this.icon,
    required this.label,
    required this.textTheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: AppSpacing.iconMd,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: true,
                      applyHeightToLastDescent: true,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                    style: AppTypography.eventsGroupedRowPrimary(textTheme),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
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

class DetailChip extends StatelessWidget {
  const DetailChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.radius10,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.eventsCaptionStrong(
                      Theme.of(context).textTheme,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
