import 'package:feature_events/feature_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature_events barrel exports routes', () {
    expect(featureEventsPackageVersion, '0.0.1');
    expect(buildEventsRoutes, isNotNull);
  });
}
