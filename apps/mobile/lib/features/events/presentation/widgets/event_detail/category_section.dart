import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key, required this.event});

  final EcoEvent event;

  void _showCategoryInfo(BuildContext context) {
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
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(event.category.icon, size: 28, color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  event.category.label,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.radiusSm),
                Text(
                  event.category.description,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Event category: ${event.category.label}',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showCategoryInfo(context),
          borderRadius: BorderRadius.circular(AppSpacing.radius10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs, horizontal: AppSpacing.xxs / 2),
            child: Row(
              children: <Widget>[
                Icon(event.category.icon, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    event.category.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                Icon(
                  CupertinoIcons.info_circle,
                  size: 16,
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
