import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notification stack routes', () {
    test('defines root overlay paths for inbox and entities', () {
      expect(AppRoutes.notifications, '/notifications');
      expect(AppRoutes.reportDetail, '/reports/detail');
      expect(AppRoutes.profilePointsHistory, '/profile/points-history');
    });
  });
}
