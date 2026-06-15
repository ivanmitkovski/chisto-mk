import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('typography matrix golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                AppText.display('Display'),
                AppText.title('Title'),
                AppText.section('Section'),
                AppText.cardTitle('Card title'),
                AppText.body('Body'),
                AppText.meta('Meta'),
                AppText.caption('Caption'),
                AppText.label('Label'),
                AppText.badge('Badge'),
                AppText.metric('42'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/typography_matrix.png'),
    );
  });
}
