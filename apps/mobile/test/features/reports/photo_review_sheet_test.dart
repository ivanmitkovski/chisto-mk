import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/presentation/widgets/photo_review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('photo review shows full Macedonian button labels', (
    WidgetTester tester,
  ) async {
    const String retake = 'Сними повторно';
    const String confirm = 'Потврди фотографија';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('mk'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: Scaffold(
            body: PhotoReviewSheet(file: XFile('/tmp/test.jpg')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(retake), findsOneWidget);
    expect(find.text(confirm), findsOneWidget);
    expect(find.textContaining('...'), findsNothing);
    expect(find.byType(AppSheetFooterActions), findsOneWidget);
  });
}
