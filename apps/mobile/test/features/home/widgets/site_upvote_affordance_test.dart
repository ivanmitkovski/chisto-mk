import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_upvote_affordance.dart';

void main() {
  testWidgets('barIcon invokes onPressed once when not busy', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SiteUpvoteAffordance(
              variant: SiteUpvoteAffordanceVariant.barIcon,
              isUpvoted: false,
              isBusy: false,
              semanticsLabel: 'Upvote test site',
              onPressed: () async {
                calls++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(SiteUpvoteAffordance),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('barIcon does not invoke onPressed when busy', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SiteUpvoteAffordance(
              variant: SiteUpvoteAffordanceVariant.barIcon,
              isUpvoted: true,
              isBusy: true,
              semanticsLabel: 'Busy upvote',
              onPressed: () async {
                calls++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(SiteUpvoteAffordance),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('statChip exposes voted semantics label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SiteUpvoteAffordance(
              variant: SiteUpvoteAffordanceVariant.statChip,
              isUpvoted: true,
              isBusy: false,
              count: 42,
              semanticsLabel: 'Remove upvote for River bend',
              semanticsLongPressHint: 'Long press hint',
              onPressed: () async {},
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Remove upvote for River bend'), findsOneWidget);
  });

  testWidgets('reduce motion does not break tap', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SiteUpvoteAffordance(
                variant: SiteUpvoteAffordanceVariant.barIcon,
                isUpvoted: false,
                isBusy: false,
                semanticsLabel: 'Upvote',
                onPressed: () async {
                  calls++;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(SiteUpvoteAffordance),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pump();
    expect(calls, 1);
  });
}
