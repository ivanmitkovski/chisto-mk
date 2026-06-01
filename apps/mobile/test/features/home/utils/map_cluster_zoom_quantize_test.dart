import 'package:feature_home/src/presentation/utils/map_cluster_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quantizeZoomForClusterRecompute snaps to fixed steps', () {
    final double a = quantizeZoomForClusterRecompute(12.011);
    final double b = quantizeZoomForClusterRecompute(12.012);
    expect(a, b);
    expect((a * 112).round(), 1345);
  });
}
