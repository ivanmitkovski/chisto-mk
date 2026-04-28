import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/pollution_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PollutionMarker builds for asset-backed site', (
    WidgetTester tester,
  ) async {
    final PollutionSite site = PollutionSite(
      id: 'm1',
      title: 'Marker site',
      description: 'D',
      statusLabel: 'High',
      statusColor: Colors.red,
      distanceKm: 1,
      score: 1,
      participantCount: 0,
      mediaUrls: const <String>['assets/images/content/people_cleaning.png'],
      latitude: 41.6,
      longitude: 21.7,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PollutionMarker(
              site: site,
              isSelected: false,
              entranceDelay: Duration.zero,
              animate: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Marker site.*High')),
      findsOneWidget,
    );
  });
}
