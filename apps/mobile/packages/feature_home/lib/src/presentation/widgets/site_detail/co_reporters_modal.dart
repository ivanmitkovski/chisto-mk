import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/co_reporters_sheet_content.dart';
import 'package:flutter/material.dart';

class CoReportersModal {
  CoReportersModal._();

  static Future<void> show(BuildContext context, {required String siteId}) {
    return AppBottomSheet.showResizable<void>(
      context: context,
      sizeConfig: const AppSheetSizeConfig(
        minSize: 0.35,
        maxSize: 0.85,
        initialSize: 0.5,
      ),
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            DraggableScrollableController sheetController,
            AppSheetSizeConfig sizeConfig,
          ) {
            return CoReportersSheetContent(
              siteId: siteId,
              scrollController: scrollController,
              sheetController: sheetController,
              sizeConfig: sizeConfig,
            );
          },
    );
  }
}
