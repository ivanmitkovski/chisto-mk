import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets(
    'SiteHistorySkeleton fills viewport and exposes loading semantics',
    (WidgetTester tester) async {
      const Size size = Size(390, 844);

      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SizedBox(
              height: size.height,
              width: size.width,
              child: const SiteHistorySkeleton(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Loading site history.'), findsOneWidget);
      expect(
        find.byKey(const Key('site-history-skeleton-row-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('site-history-skeleton-row-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('site-history-skeleton-row-7')),
        findsOneWidget,
      );
    },
  );
}
