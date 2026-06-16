import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_owner_socket_stream.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_connection_state.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_service.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/reports_list_realtime_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reconnecting state does not show banner', (
    WidgetTester tester,
  ) async {
    final AuthState auth = AuthState()
      ..setAuthenticated(userId: 'u1', displayName: 'Test', accessToken: 'tok');
    final ReportsOwnerSocketStream transport = ReportsOwnerSocketStream(
      baseUrl: 'http://127.0.0.1:9',
      authState: auth,
    );
    final ReportsRealtimeService svc = ReportsRealtimeService.withTransport(
      transport,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          reportsRealtimeServiceProvider.overrideWithValue(svc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ReportsListRealtimeBanner()),
        ),
      ),
    );

    transport.hasReachedLive.value = true;
    transport.connectionState.value =
        ReportsRealtimeConnectionState.reconnecting;
    transport.disruptionVisible.value = true;
    await tester.pump();
    expect(find.text('Reconnecting…'), findsNothing);
  });

  testWidgets('offline state shows banner with try again', (
    WidgetTester tester,
  ) async {
    final AuthState auth = AuthState()
      ..setAuthenticated(userId: 'u1', displayName: 'Test', accessToken: 'tok');
    final ReportsOwnerSocketStream transport = ReportsOwnerSocketStream(
      baseUrl: 'http://127.0.0.1:9',
      authState: auth,
    );
    final ReportsRealtimeService svc = ReportsRealtimeService.withTransport(
      transport,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          reportsRealtimeServiceProvider.overrideWithValue(svc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ReportsListRealtimeBanner()),
        ),
      ),
    );

    transport.connectionState.value = ReportsRealtimeConnectionState.offline;
    await tester.pump();
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
