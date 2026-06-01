import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_tile.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('tap with cleanupEventId navigates to event detail', (
    WidgetTester tester,
  ) async {
    readRoot(homeShellControllerProvider.notifier);
    buildAppGoRouter(initialLocation: AppRoutes.home);

    await tester.pumpWidget(
      wrapForWidgetTest(
        SiteHistoryTimelineTile(
          entry: SiteHistoryEntry(
            id: 'e1',
            kind: SiteHistoryEntryKind.cleanupEventScheduled,
            occurredAt: DateTime(2026, 5, 20),
            cleanupEventId: 'event-42',
          ),
          showLineAbove: false,
          showLineBelow: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cleanup event scheduled'));
    await tester.pumpAndSettle();

    expect(
      appGoRouter.routeInformationProvider.value.uri.path,
      '${AppRoutes.eventsDetail}/event-42',
    );
  });

  testWidgets('tap with note toggles show more / show less', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        SiteHistoryTimelineTile(
          entry: SiteHistoryEntry(
            id: 'n1',
            kind: SiteHistoryEntryKind.adminNote,
            occurredAt: DateTime(2026, 5, 20),
            note: 'Moderator left a detailed note about this site.',
          ),
          showLineAbove: true,
          showLineBelow: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show more'), findsOneWidget);
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('entry without note or event is not a button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(
        SiteHistoryTimelineTile(
          entry: SiteHistoryEntry(
            id: 'e2',
            kind: SiteHistoryEntryKind.siteCreated,
            occurredAt: DateTime(2026, 5, 20),
          ),
          showLineAbove: false,
          showLineBelow: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final SemanticsNode node = tester.getSemantics(
      find.byType(SiteHistoryTimelineTile),
    );
    expect(node.hasFlag(SemanticsFlag.isButton), isFalse);
  });
}
