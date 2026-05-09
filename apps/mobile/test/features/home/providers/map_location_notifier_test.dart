import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_location_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService({
    this.enabled = true,
  });

  bool enabled;
  AppLocationPermission permission = AppLocationPermission.whileInUse;
  GeoPosition position = const GeoPosition(latitude: 41.61, longitude: 21.75);
  final StreamController<GeoPosition> stream = StreamController<GeoPosition>.broadcast();

  @override
  Future<AppLocationPermission> checkPermission() async => permission;

  @override
  Future<GeoPosition> getCurrentPosition({
    required AppGeoAccuracy accuracy,
    Duration? timeLimit,
  }) async => position;

  @override
  Stream<GeoPosition> watchPosition({required GeoWatchOptions options}) {
    return stream.stream;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<AppLocationPermission> requestPermission() async => permission;
}

void main() {
  test('tryInitialLocate sets user location on allowed permission', () async {
    final _FakeLocationService fake = _FakeLocationService();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        locationServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    await container.read(mapLocationNotifierProvider.notifier).tryInitialLocate();
    expect(container.read(mapLocationNotifierProvider).userLocation, isNotNull);
  });

  test('locateUserBest returns null when service disabled', () async {
    final _FakeLocationService fake = _FakeLocationService(enabled: false);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        locationServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    final GeoPosition? pos =
        await container.read(mapLocationNotifierProvider.notifier).locateUserBest();
    expect(pos, isNull);
  });

  test('start/stop foreground tracking updates tracking state', () async {
    final _FakeLocationService fake = _FakeLocationService();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        locationServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(() async {
      await fake.stream.close();
      container.dispose();
    });
    final MapLocationNotifier notifier =
        container.read(mapLocationNotifierProvider.notifier);

    final bool started = await notifier.startForegroundTracking();
    expect(started, isTrue);
    expect(container.read(mapLocationNotifierProvider).isTracking, isTrue);

    fake.stream.add(const GeoPosition(latitude: 41.7, longitude: 21.8));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(mapLocationNotifierProvider).userLocation, isNotNull);

    await notifier.stopForegroundTracking();
    expect(container.read(mapLocationNotifierProvider).isTracking, isFalse);
  });

  test('startForegroundTracking is idempotent', () async {
    final _FakeLocationService fake = _FakeLocationService();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        locationServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(() async {
      await fake.stream.close();
      container.dispose();
    });
    final MapLocationNotifier notifier =
        container.read(mapLocationNotifierProvider.notifier);

    expect(await notifier.startForegroundTracking(), isTrue);
    expect(await notifier.startForegroundTracking(), isTrue);
    expect(container.read(mapLocationNotifierProvider).isTracking, isTrue);
  });
}
