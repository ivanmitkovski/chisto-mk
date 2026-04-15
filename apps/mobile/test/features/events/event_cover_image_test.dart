import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EcoEventCoverImage', () {
    test('isNetworkUrl', () {
      expect(EcoEventCoverImage.isNetworkUrl('https://example.com/a.jpg'), isTrue);
      expect(EcoEventCoverImage.isNetworkUrl('http://x/y'), isTrue);
      expect(EcoEventCoverImage.isNetworkUrl('  HTTPS://x '), isTrue);
      expect(EcoEventCoverImage.isNetworkUrl('assets/x.png'), isFalse);
      expect(EcoEventCoverImage.isNetworkUrl(''), isFalse);
    });

    testWidgets('uses AssetImage for asset path', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EcoEventCoverImage(
              path: 'assets/images/references/onboarding_reference.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
    });
  });
}
