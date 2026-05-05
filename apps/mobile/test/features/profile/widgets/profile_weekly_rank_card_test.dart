import 'package:chisto_mobile/features/profile/data/profile_me_json.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_weekly_rank_card.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfileWeeklyRankCard exposes weekly rank semantics and taps',
      (WidgetTester tester) async {
    final ProfileUser user = profileUserFromMeJson(<String, dynamic>{
      'id': 'u1',
      'firstName': 'A',
      'lastName': 'B',
      'email': 'a@b.c',
      'phoneNumber': '+1',
      'pointsBalance': 0,
      'totalPointsEarned': 0,
      'level': 1,
      'levelProgress': 0,
      'pointsInLevel': 0,
      'pointsToNextLevel': 10,
      'weeklyPoints': 12,
      'weeklyRank': 3,
      'weekStartsAt': '',
      'weekEndsAt': '',
    });

    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ProfileWeeklyRankCard(
            user: user,
            onViewRankings: () => taps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp(r'^Weekly rank\. Opens rankings\.'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel(RegExp(r'^Weekly rank\. Opens rankings\.')));
    expect(taps, 1);
  });
}
