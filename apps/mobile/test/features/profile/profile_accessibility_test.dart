import 'package:chisto_mobile/features/profile/data/profile_me_json.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_level_points_card.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('Profile level card meets Android tap target guideline',
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
      'weeklyPoints': 0,
      'weeklyRank': null,
      'weekStartsAt': '',
      'weekEndsAt': '',
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ProfileLevelAndPointsCard(
            user: user,
            onOpenPointsHistory: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
