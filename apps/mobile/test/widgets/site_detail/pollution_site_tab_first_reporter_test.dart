import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_avatar.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/site_reported_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SiteReportedRow shows reported-by line and reporter name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: SiteReportedRow(
            reporterName: 'Alice First',
            reportedAgo: '3 days ago',
            reporterAvatarUrl: 'https://cdn.example/alice.jpg',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SiteReportedRow), findsOneWidget);
    expect(find.byType(AppAvatar), findsOneWidget);
  });
}
