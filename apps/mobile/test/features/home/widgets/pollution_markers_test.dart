import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/pollution_markers.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
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
      find.bySemanticsLabel('Marker site, High. Double tap to preview.'),
      findsOneWidget,
    );
  });

  Widget _goldenShell({required Widget child}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        backgroundColor: const Color(0xFFE8EEF2),
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('golden-pin'),
            child: SizedBox(width: 140, height: 140, child: child),
          ),
        ),
      ),
    );
  }

  PollutionSite _site({
    required String id,
    required Color statusColor,
    required String statusLabel,
  }) {
    return PollutionSite(
      id: id,
      title: 'Golden $id',
      description: 'D',
      statusLabel: statusLabel,
      statusColor: statusColor,
      distanceKm: 1,
      score: 1,
      participantCount: 0,
      mediaUrls: const <String>['assets/images/content/people_cleaning.png'],
      latitude: 41.6,
      longitude: 21.7,
    );
  }

  testWidgets('PollutionMarker golden — cold (blue) variant', (WidgetTester tester) async {
    await tester.pumpWidget(
      _goldenShell(
        child: PollutionMarker(
          site: _site(
            id: 'g-cold',
            statusColor: Colors.blue,
            statusLabel: 'Moderate',
          ),
          isSelected: false,
          entranceDelay: Duration.zero,
          animate: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('golden-pin')),
      matchesGoldenFile('goldens/pollution_marker_cold.png'),
    );
  });

  testWidgets('PollutionMarker golden — hot (red) selected', (WidgetTester tester) async {
    await tester.pumpWidget(
      _goldenShell(
        child: PollutionMarker(
          site: _site(
            id: 'g-hot',
            statusColor: Colors.red,
            statusLabel: 'High',
          ),
          isSelected: true,
          entranceDelay: Duration.zero,
          animate: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('golden-pin')),
      matchesGoldenFile('goldens/pollution_marker_hot_selected.png'),
    );
  });

  testWidgets('ClusterMarker golden — bucket of 12', (WidgetTester tester) async {
    final PollutionSite a = _site(
      id: 'c1',
      statusColor: Colors.orange,
      statusLabel: 'High',
    );
    final ClusterBucket bucket = ClusterBucket(
      center: const LatLng(41.6, 21.7),
      sites: List<PollutionSite>.generate(12, (int i) => a),
    );
    await tester.pumpWidget(
      _goldenShell(
        child: ClusterMarker(
          bucket: bucket,
          count: 12,
          entranceDelay: Duration.zero,
          animate: false,
          pulseEnabled: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey<String>('golden-pin')),
      matchesGoldenFile('goldens/pollution_cluster_12.png'),
    );
  });
}
