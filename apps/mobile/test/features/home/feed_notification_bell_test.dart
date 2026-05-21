import 'package:chisto_mobile/features/home/presentation/widgets/feed_notification_bell.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('plays swing when unread count increases', (WidgetTester tester) async {
    final GlobalKey<FeedNotificationBellState> bellKey =
        GlobalKey<FeedNotificationBellState>();

    await tester.pumpWidget(
      _BellTestHarness(
        bellKey: bellKey,
        unreadCount: ValueNotifier<int>(0),
        disableAnimations: false,
      ),
    );
    final ValueNotifier<int> count =
        tester.widget<_BellTestHarness>(find.byType(_BellTestHarness)).unreadCount;
    count.value = 1;
    await tester.pump();
    expect(bellKey.currentState!.swingController.isAnimating, isTrue);

    await tester.pump(const Duration(milliseconds: 140));
    expect(bellKey.currentState!.swingRotation.value, lessThan(0));
    expect(
      bellKey.currentState!.swingRotation.value.abs(),
      greaterThan(0.08),
    );
  });

  testWidgets('skips swing when reduce motion is enabled', (WidgetTester tester) async {
    final GlobalKey<FeedNotificationBellState> bellKey =
        GlobalKey<FeedNotificationBellState>();

    await tester.pumpWidget(
      _BellTestHarness(
        bellKey: bellKey,
        unreadCount: ValueNotifier<int>(0),
        disableAnimations: true,
      ),
    );
    final ValueNotifier<int> count =
        tester.widget<_BellTestHarness>(find.byType(_BellTestHarness)).unreadCount;
    count.value = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(bellKey.currentState!.swingController.isAnimating, isFalse);
    expect(bellKey.currentState!.swingRotation.value, 0);
  });

  testWidgets('badge is not inside rotating transform', (WidgetTester tester) async {
    await tester.pumpWidget(
      _BellTestHarness(
        bellKey: GlobalKey<FeedNotificationBellState>(),
        unreadCount: ValueNotifier<int>(3),
        disableAnimations: false,
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.byType(Transform), findsWidgets);
  });
}

class _BellTestHarness extends StatelessWidget {
  const _BellTestHarness({
    required this.bellKey,
    required this.unreadCount,
    required this.disableAnimations,
  });

  final GlobalKey<FeedNotificationBellState> bellKey;
  final ValueNotifier<int> unreadCount;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: unreadCount,
            builder: (BuildContext context, int count, Widget? _) {
              return FeedNotificationBell(
                key: bellKey,
                unreadCount: count,
                onTap: () {},
              );
            },
          ),
        ),
      ),
    );
  }
}
