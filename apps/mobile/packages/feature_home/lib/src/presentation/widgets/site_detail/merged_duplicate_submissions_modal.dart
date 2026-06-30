import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Explains merged duplicate reports when the primary reporter merged their own duplicates (no co-reporter rows).
class MergedDuplicateSubmissionsModal extends StatelessWidget {
  const MergedDuplicateSubmissionsModal({super.key, required this.count});

  final int count;

  static Future<void> show(BuildContext context, {required int count}) {
    if (count <= 0) {
      return Future<void>.value();
    }
    return AppBottomSheet.show<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (BuildContext context) =>
          MergedDuplicateSubmissionsModal(count: count),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: AppSpacing.sheetHandle,
              height: AppSpacing.sheetHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.siteMergedDuplicatesModalTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.siteMergedDuplicatesModalBody(count),
            style: AppTypographySurfaces.homeMergedDuplicateBody(
              Theme.of(context).textTheme,
            ),
          ),
        ],
      ),
    );
  }
}
