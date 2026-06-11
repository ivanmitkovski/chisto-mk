import 'package:chisto_infrastructure/core/presence/presence_screen_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps router paths to admin-friendly screen labels', () {
    expect(presenceScreenLabelForPath('/feed'), 'Pollution Feed');
    expect(presenceScreenLabelForPath('/map'), 'Map');
    expect(presenceScreenLabelForPath('/events'), 'Events');
    expect(presenceScreenLabelForPath('/sites/abc'), 'Site Detail');
    expect(presenceScreenLabelForPath('/reports/new'), 'New Report');
    expect(presenceScreenLabelForPath('/reports'), 'Reports');
  });

  test('strips query params before matching', () {
    expect(presenceScreenLabelForPath('/feed?tab=nearby'), 'Pollution Feed');
  });

  test('falls back to raw path or Home', () {
    expect(presenceScreenLabelForPath('/unknown-route'), '/unknown-route');
    expect(presenceScreenLabelForPath(''), 'Home');
  });
}
