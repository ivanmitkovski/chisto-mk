import 'dart:async';
import 'dart:convert';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_realtime_service.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_site_event.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Never emits SSE bytes until [close] — then the response stream completes.
class _HangUntilCloseClient extends http.BaseClient {
  final StreamController<List<int>> _body = StreamController<List<int>>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      _body.stream,
      200,
      headers: <String, String>{'content-type': 'text/event-stream'},
    );
  }

  @override
  void close() {
    if (!_body.isClosed) {
      unawaited(_body.close());
    }
    super.close();
  }
}

void main() {
  late Future<List<ConnectivityResult>> Function() _origCheck;
  late Stream<List<ConnectivityResult>> Function() _origWatch;

  setUp(() {
    _origCheck = ConnectivityGate.check;
    _origWatch = ConnectivityGate.watch;
    ConnectivityGate.check =
        () async => <ConnectivityResult>[ConnectivityResult.wifi];
    ConnectivityGate.watch =
        () => const Stream<List<ConnectivityResult>>.empty();
  });

  tearDown(() {
    ConnectivityGate.check = _origCheck;
    ConnectivityGate.watch = _origWatch;
  });

  test('connect reaches live and forwards site events', () async {
    final String eventJson = jsonEncode(<String, Object?>{
      'eventId': 'site-1:123:site_updated',
      'type': 'site_updated',
      'siteId': 'site-1',
      'occurredAtMs': 1_700_000_000_000,
      'updatedAt': '2026-03-27T12:00:00.000Z',
      'mutation': <String, Object?>{
        'kind': 'status_changed',
        'status': 'VERIFIED',
        'latitude': 41.9973,
        'longitude': 21.428,
      },
    });
    final http.Client client = MockClient.streaming(
      (http.BaseRequest request, _) async {
        return http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode('data: $eventJson\n\n')),
          200,
          headers: <String, String>{'content-type': 'text/event-stream'},
        );
      },
    );
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't1',
      );
    final MapRealtimeService svc = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      sessionRefresh: null,
      httpClient: client,
    );
    final List<MapRealtimeConnectionState> states = <MapRealtimeConnectionState>[];
    final StreamSubscription<MapRealtimeConnectionState> sub =
        svc.states.listen(states.add);
    final List<MapSiteEvent> events = <MapSiteEvent>[];
    final StreamSubscription<MapSiteEvent> evSub = svc.events.listen(events.add);

    svc.setActive(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(states, contains(MapRealtimeConnectionState.live));
    expect(events, isNotEmpty);
    expect(events.first.siteId, 'site-1');

    svc.setActive(false);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    await evSub.cancel();
    svc.dispose();
  });

  test('401 with session refresh retries without signing out', () async {
    int sends = 0;
    final String okBody = jsonEncode(<String, Object?>{
      'eventId': 'site-2:1:site_updated',
      'type': 'site_updated',
      'siteId': 'site-2',
      'occurredAtMs': 1,
      'updatedAt': '2026-03-27T12:00:00.000Z',
      'mutation': <String, String>{'kind': 'updated'},
    });
    final http.Client client = MockClient.streaming(
      (http.BaseRequest request, _) async {
        sends += 1;
        if (sends == 1) {
          return http.StreamedResponse(const Stream<List<int>>.empty(), 401);
        }
        expect(request.headers['authorization'], 'Bearer t2');
        return http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode('data: $okBody\n\n')),
          200,
          headers: <String, String>{'content-type': 'text/event-stream'},
        );
      },
    );
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't1',
      );
    final MapRealtimeService svc = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      sessionRefresh: () async {
        auth.setAuthenticated(
          userId: 'u1',
          displayName: 'Tester',
          accessToken: 't2',
        );
        return true;
      },
      httpClient: client,
    );
    svc.setActive(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(sends, 2);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.accessToken, 't2');

    svc.setActive(false);
    svc.dispose();
  });

  test('401 without refresh signs out', () async {
    final http.Client client = MockClient.streaming(
      (http.BaseRequest request, _) async {
        return http.StreamedResponse(const Stream<List<int>>.empty(), 401);
      },
    );
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't1',
      );
    final MapRealtimeService svc = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      sessionRefresh: () async => false,
      httpClient: client,
    );
    svc.setActive(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(auth.isAuthenticated, isFalse);

    svc.dispose();
  });

  test('watchdog forces reconnect after sustained silence', () {
    fakeAsync((FakeAsync clock) {
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Tester',
          accessToken: 'tok',
        );
      http.runWithClient(() {
        final MapRealtimeService svc = MapRealtimeService(
          config: AppConfig.local,
          authState: auth,
          sessionRefresh: null,
          httpClient: null,
        );
        final List<MapRealtimeConnectionState> states =
            <MapRealtimeConnectionState>[];
        svc.states.listen(states.add);
        svc.setActive(true);
        clock.flushMicrotasks();
        clock.elapse(const Duration(seconds: 76));
        clock.flushMicrotasks();
        expect(
          states.contains(MapRealtimeConnectionState.reconnecting),
          isTrue,
          reason: 'states=$states',
        );
        svc.setActive(false);
        svc.dispose();
      }, _HangUntilCloseClient.new);
    });
  });

  test('requestReconnect closes active stream and allows another send', () async {
    int sends = 0;
    final StreamController<List<int>> first = StreamController<List<int>>();
    final http.Client client = MockClient.streaming(
      (http.BaseRequest request, _) async {
        sends += 1;
        if (sends == 1) {
          return http.StreamedResponse(
            first.stream,
            200,
            headers: <String, String>{'content-type': 'text/event-stream'},
          );
        }
        return http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode('\n')),
          200,
          headers: <String, String>{'content-type': 'text/event-stream'},
        );
      },
    );
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't1',
      );
    final MapRealtimeService svc = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      sessionRefresh: null,
      httpClient: client,
    );
    final Completer<void> sawLive = Completer<void>();
    late final StreamSubscription<MapRealtimeConnectionState> stateSub;
    stateSub = svc.states.listen((MapRealtimeConnectionState s) {
      if (s == MapRealtimeConnectionState.live && !sawLive.isCompleted) {
        sawLive.complete();
      }
    });
    svc.setActive(true);
    await sawLive.future.timeout(const Duration(seconds: 2));
    await stateSub.cancel();
    svc.requestReconnect();
    // Backoff after a dropped stream is ~400–600ms (see [_nextBackoff]).
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(sends, greaterThanOrEqualTo(2));
    await first.close();
    svc.setActive(false);
    svc.dispose();
  });

  test('setActive false stops without throwing', () async {
    final http.Client client = MockClient.streaming(
      (http.BaseRequest request, _) async {
        return http.StreamedResponse(
          const Stream<List<int>>.empty(),
          200,
          headers: <String, String>{'content-type': 'text/event-stream'},
        );
      },
    );
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 't1',
      );
    final MapRealtimeService svc = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      sessionRefresh: null,
      httpClient: client,
    );
    svc.setActive(true);
    await Future<void>.delayed(Duration.zero);
    svc.setActive(false);
    await Future<void>.delayed(Duration.zero);
    svc.dispose();
  });
}
