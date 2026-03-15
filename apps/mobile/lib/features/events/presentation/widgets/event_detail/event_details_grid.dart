import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class EventDetailsGrid extends StatelessWidget {
  const EventDetailsGrid({super.key, required this.event});

  final EcoEvent event;

  static void _showInfoSheet(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radius14),
                  ),
                  child: Icon(icon, size: 26, color: color),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.radiusSm),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
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

    return Row(
      children: <Widget>[
        if (hasScale)
          Expanded(
            child: DetailChip(
              icon: Icons.groups_rounded,
              label: event.scale!.label,
              color: AppColors.primaryDark,
              onTap: () => _showInfoSheet(
                context,
                icon: Icons.groups_rounded,
                title: event.scale!.label,
                description: event.scale!.description,
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
              label: event.difficulty!.label,
              color: event.difficulty!.color,
              onTap: () => _showInfoSheet(
                context,
                icon: CupertinoIcons.shield_fill,
                title: event.difficulty!.label,
                description: event.difficulty!.description,
                color: event.difficulty!.color,
              ),
            ),
          ),
      ],
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
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
