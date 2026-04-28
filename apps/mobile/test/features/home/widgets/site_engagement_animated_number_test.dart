import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_engagement_animated_number.dart';

void main() {
  testWidgets('renders value and survives count change', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SiteEngagementAnimatedNumber(
            value: 3,
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SiteEngagementAnimatedNumber(
            value: 4,
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
  });
}
