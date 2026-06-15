import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadBundledRoboto() async {
  final FontLoader loader = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  await loader.load();
}

ThemeData _typographyGoldenTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.appBackground,
    fontFamily: 'Roboto',
    textTheme: AppTypography.textTheme.apply(fontFamily: 'Roboto'),
  );
}

void main() {
  setUpAll(_loadBundledRoboto);

  testWidgets('typography matrix golden', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 900),
          devicePixelRatio: 1,
          textScaler: TextScaler.linear(1),
          disableAnimations: true,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _typographyGoldenTheme(),
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
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/typography_matrix.png'),
    );
  });
}
