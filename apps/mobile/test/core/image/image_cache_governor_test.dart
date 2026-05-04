import 'package:chisto_mobile/core/image/image_cache_governor.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ImageCacheGovernor.instance.uninstall();
  });

  test('install sets ImageCache caps', () {
    ImageCacheGovernor.instance.install();
    final ImageCache cache = PaintingBinding.instance.imageCache;
    expect(cache.maximumSize, 200);
    expect(cache.maximumSizeBytes, 96 << 20);
  });
}
