import 'package:chisto_mobile/features/home/presentation/providers/map_ui_mode_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MapUiModeState copyWith updates only provided fields', () {
    const MapUiModeState s = MapUiModeState(
      useDarkTiles: false,
      showHeatmap: false,
      rotationLocked: true,
    );
    final MapUiModeState next = s.copyWith(showHeatmap: true);
    expect(next.showHeatmap, isTrue);
    expect(next.useDarkTiles, isFalse);
    expect(next.rotationLocked, isTrue);
  });
}
