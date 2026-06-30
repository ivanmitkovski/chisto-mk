import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/presentation/screens/profile_general_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

ProfileUser _user() {
  return const ProfileUser(
    id: 'u1',
    name: 'Jana Stefkovska',
    firstName: 'Jana',
    lastName: 'Stefkovska',
    email: 'jana@example.com',
    phoneNumber: '+38975770803',
    points: 27,
    totalPointsEarned: 63,
    level: 2,
    levelTierKey: 'level2',
    levelDisplayName: 'Level 2',
    pointsToNextLevel: 15,
    levelProgress: 0.6,
    pointsInLevel: 27,
    weeklyPoints: 113,
    weeklyRank: 1,
    weekStartsAt: '2026-06-08',
    weekEndsAt: '2026-06-14',
    avatarColorValue: 0xFF2FD788,
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfileGeneralInfoScreen renders header and fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(ProfileGeneralInfoScreen(user: _user())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('General info'), findsOneWidget);
    expect(find.text('Update info'), findsOneWidget);
    expect(find.text('jana@example.com'), findsOneWidget);
    expect(
      find.text('For email and phone number changes, contact support.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
  });

  // Regression: tapping the avatar opened a full-screen green "Update info"
  // pill that hid the form. The bottom CTA must stay a short bar.
  testWidgets('ProfileGeneralInfoScreen on iPhone size with insets + big text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1320, 2868); // iPhone 16 Pro Max px
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapForWidgetTest(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(440, 956),
            devicePixelRatio: 3,
            padding: EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(1.3),
          ),
          child: ProfileGeneralInfoScreen(user: _user()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The body header and fields must be visible (not collapsed behind the CTA).
    expect(find.text('General info'), findsOneWidget);
    expect(find.text('jana@example.com'), findsOneWidget);

    // The CTA must be a short bottom bar, not a full-screen green block.
    final Size screenSize = tester.getSize(
      find.byType(ProfileGeneralInfoScreen),
    );
    final Size ctaSize = tester.getSize(
      find.widgetWithText(PrimaryButton, 'Update info'),
    );
    expect(
      ctaSize.height < screenSize.height / 2,
      isTrue,
      reason:
          'Update info CTA should be a bottom bar, not fill the screen '
          '(cta=${ctaSize.height}, screen=${screenSize.height})',
    );
  });
}
