import 'package:feature_notifications/src/domain/models/notification_actor.dart';
import 'package:feature_notifications/src/presentation/widgets/notification_actor_avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders overflow badge when more than maxVisible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationActorAvatarStack(
            actors: <NotificationActor>[
              NotificationActor(id: '1', displayName: 'A'),
              NotificationActor(id: '2', displayName: 'B'),
              NotificationActor(id: '3', displayName: 'C'),
              NotificationActor(id: '4', displayName: 'D'),
            ],
            overflowCount: 1,
          ),
        ),
      ),
    );

    expect(find.text('+1'), findsOneWidget);
  });
}
