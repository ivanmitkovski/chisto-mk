import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('design system package is wired', () {
    expect(AppColors.primary, isNotNull);
    expect(AppTheme.light, isNotNull);
    expect(designSystemPackageVersion, '0.0.1');
  });
}
