import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_labels.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets(
    'SiteHistoryTimelineNode uses per-kind accent for approved entries',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForWidgetTest(
          const SiteHistoryTimelineNode(
            kind: SiteHistoryEntryKind.reportApproved,
          ),
        ),
      );

      final Container container = tester.widget(find.byType(Container).first);
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        siteHistoryEntryAccentBackground(SiteHistoryEntryKind.reportApproved),
      );

      final Icon icon = tester.widget(
        find.byIcon(Icons.check_circle_outline_rounded),
      );
      expect(icon.color, AppColors.primaryDark);
    },
  );

  testWidgets(
    'SiteHistoryTimelineNode uses blue accent for submitted reports',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForWidgetTest(
          const SiteHistoryTimelineNode(
            kind: SiteHistoryEntryKind.reportSubmitted,
          ),
        ),
      );

      final Icon icon = tester.widget(find.byIcon(Icons.flag_outlined));
      expect(icon.color, AppColors.notificationReport);
      expect(icon.color, isNot(AppColors.textMuted));
    },
  );
}
