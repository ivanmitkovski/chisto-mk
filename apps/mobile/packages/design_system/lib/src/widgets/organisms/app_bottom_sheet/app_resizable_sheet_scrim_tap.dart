import 'package:flutter/widgets.dart';

/// Tap-to-dismiss layer for the dimmed area above a resizable bottom sheet.
///
/// Scroll-controlled modal routes clip the barrier to the sheet's laid-out
/// height, which leaves a non-dismissible gap above the visible panel when the
/// host applies notch padding. This overlay fills that gap.
class AppResizableSheetScrimTap extends StatelessWidget {
  const AppResizableSheetScrimTap({
    super.key,
    required this.sheetController,
    required this.topInset,
    required this.initialExtent,
    required this.onTap,
    required this.child,
  });

  final DraggableScrollableController sheetController;
  final double topInset;
  final double initialExtent;
  final VoidCallback onTap;
  final Widget child;

  double _visibleSheetTop(double screenHeight, double extent) {
    final double slotHeight = (screenHeight - topInset).clamp(0.0, screenHeight);
    final double visibleHeight = extent * slotHeight;
    return (screenHeight - visibleHeight).clamp(0.0, screenHeight);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;

    return ListenableBuilder(
      listenable: sheetController,
      builder: (BuildContext context, Widget? sheet) {
        final double extent = sheetController.isAttached
            ? sheetController.size
            : initialExtent;
        final double dismissHeight = _visibleSheetTop(screenHeight, extent);

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            sheet!,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: dismissHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
