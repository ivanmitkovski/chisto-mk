import 'package:chisto_mobile/features/profile/data/profile_me_json.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_level_points_card.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfileLevelAndPointsCard exposes level card semantics and taps',
      (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
    final ProfileUser user = profileUserFromMeJson(<String, dynamic>{
      'id': 'u1',
      'firstName': 'A',
      'lastName': 'B',
      'email': 'a@b.c',
      'phoneNumber': '+1',
      'pointsBalance': 10,
      'totalPointsEarned': 50,
      'level': 2,
      'levelProgress': 0.5,
      'pointsInLevel': 5,
      'pointsToNextLevel': 5,
      'weeklyPoints': 0,
      'weeklyRank': null,
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
          body: ProfileLevelAndPointsCard(
            user: user,
            onOpenPointsHistory: () => taps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(r'^Level and points\. Opens points history')),
      findsOneWidget,
    );

    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^Level and points\. Opens points history')),
    );
    expect(taps, 1);
    } finally {
      semantics.dispose();
    }
  });
}
