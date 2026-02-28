import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/main.dart';

void main() {
  testWidgets('renders Chisto home title', (WidgetTester tester) async {
    await tester.pumpWidget(const ChistoApp());
    expect(find.text('Chisto.mk'), findsOneWidget);
  });
}
