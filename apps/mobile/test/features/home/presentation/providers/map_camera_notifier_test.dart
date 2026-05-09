import 'package:chisto_mobile/features/home/presentation/providers/map_camera_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setCamera updates notifier state', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(mapCameraNotifierProvider.notifier)
        .setCamera(centerLat: 41.2, centerLng: 21.3, zoom: 9.5);

    final MapCameraState s = container.read(mapCameraNotifierProvider);
    expect(s.centerLat, 41.2);
    expect(s.centerLng, 21.3);
    expect(s.zoom, 9.5);
  });
}
