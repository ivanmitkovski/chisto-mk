import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared modal chrome for site comments (feed cards + site detail).
///
/// Matches keyboard-safe [DraggableScrollableSheet] sizing used on the feed so the
/// composer stays visible when the software keyboard opens.
Future<void> showPollutionSiteCommentsModalBottomSheet(
  BuildContext context, {
  required Widget Function(
    BuildContext sheetContext,
    ScrollController scrollController,
  ) builder,
}) async {
  final DraggableScrollableController sheetController =
      DraggableScrollableController();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    useSafeArea: true,
    barrierColor: AppColors.overlay,
    backgroundColor: AppColors.transparent,
    builder: (BuildContext sheetContext) {
      final bool keyboardOpen =
          MediaQuery.of(sheetContext).viewInsets.bottom > 0;
      if (keyboardOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!sheetController.isAttached) {
            return;
          }
          if (sheetController.size >= 0.94) {
            return;
          }
          sheetController.animateTo(
            0.95,
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
          );
        });
      }
      return DraggableScrollableSheet(
        controller: sheetController,
        expand: false,
        initialChildSize: keyboardOpen ? 0.95 : 0.74,
        minChildSize: keyboardOpen ? 0.95 : 0.56,
        maxChildSize: 0.95,
        snap: !keyboardOpen,
        snapSizes: keyboardOpen ? null : const <double>[0.74, 0.95],
        builder: (BuildContext _, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusPill),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: builder(sheetContext, scrollController),
          );
        },
      );
    },
  );
}
