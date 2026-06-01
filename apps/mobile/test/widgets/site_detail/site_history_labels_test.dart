import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('admin moderation entries show By admin instead of name', (
    WidgetTester tester,
  ) async {
    late String? subtitle;
    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            subtitle = siteHistoryEntrySubtitle(
              context,
              SiteHistoryEntry(
                id: '1',
                kind: SiteHistoryEntryKind.reportApproved,
                occurredAt: DateTime(2026, 5, 20),
                actorDisplayName: 'Melanija Stojcheva',
                actorRole: 'ADMIN',
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(subtitle, 'By admin');
  });

  testWidgets('reporter entries still show the actor name', (
    WidgetTester tester,
  ) async {
    late String? subtitle;
    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            subtitle = siteHistoryEntrySubtitle(
              context,
              SiteHistoryEntry(
                id: '2',
                kind: SiteHistoryEntryKind.reportSubmitted,
                occurredAt: DateTime(2026, 5, 20),
                actorDisplayName: 'Melanija Stojcheva',
                actorRole: 'USER',
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(subtitle, 'By Melanija Stojcheva');
  });

  testWidgets('admin status changes show By admin', (
    WidgetTester tester,
  ) async {
    late String? subtitle;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            subtitle = siteHistoryEntrySubtitle(
              context,
              SiteHistoryEntry(
                id: '3',
                kind: SiteHistoryEntryKind.statusChanged,
                occurredAt: DateTime(2026, 5, 20),
                fromStatus: 'REPORTED',
                toStatus: 'VERIFIED',
                actorDisplayName: 'Melanija Stojcheva',
                actorRole: 'SUPPORT',
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(subtitle, 'By admin');
  });

  testWidgets('status changes with actor show By admin even without role', (
    WidgetTester tester,
  ) async {
    late String? subtitle;
    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            subtitle = siteHistoryEntrySubtitle(
              context,
              SiteHistoryEntry(
                id: '4',
                kind: SiteHistoryEntryKind.statusChanged,
                occurredAt: DateTime(2026, 5, 20),
                fromStatus: 'REPORTED',
                toStatus: 'VERIFIED',
                actorDisplayName: 'Ivan Mitkovski',
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(subtitle, 'By admin');
  });
}
