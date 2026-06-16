import 'package:feature_auth/src/data/user_home_location_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserHomeLocationStore', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test(
      'applyFromProfileJson clears when homeLocationSetAt is null',
      () async {
        await prefs.setDouble(kUserHomeLatitudeKey, 41.99);
        await prefs.setDouble(kUserHomeLongitudeKey, 21.43);

        final UserHomeLocationStore store = UserHomeLocationStore(
          prefs,
          userId: 'user-1',
        );
        await store.applyFromProfileJson(<String, dynamic>{
          'homeLatitude': 41.99,
          'homeLongitude': 21.43,
          'homeLocationSetAt': null,
        });

        expect(store.hasHomeLocation, isFalse);
        expect(store.hasConfirmedHomeLocation, isFalse);
      },
    );

    test(
      'applyFromProfileJson saves confirmed home with scoped keys',
      () async {
        final UserHomeLocationStore store = UserHomeLocationStore(
          prefs,
          userId: 'user-1',
        );
        await store.applyFromProfileJson(<String, dynamic>{
          'homeLatitude': 41.9981,
          'homeLongitude': 21.4254,
          'homeLocationSetAt': '2026-06-08T12:00:00.000Z',
          'homeLocationLabel': 'Skopje',
        });

        expect(store.hasConfirmedHomeLocation, isTrue);
        expect(store.latitude, closeTo(41.9981, 0.0001));
        expect(store.longitude, closeTo(21.4254, 0.0001));
        expect(store.homeLocationSetAt, '2026-06-08T12:00:00.000Z');
        expect(prefs.getDouble('chisto_home_latitude_user-1'), isNotNull);
        expect(prefs.getDouble(kUserHomeLatitudeKey), isNull);
      },
    );

    test(
      'scoped store ignores legacy global coords until server sync',
      () async {
        await prefs.setDouble(kUserHomeLatitudeKey, 41.99);
        await prefs.setDouble(kUserHomeLongitudeKey, 21.43);

        final UserHomeLocationStore store = UserHomeLocationStore(
          prefs,
          userId: 'user-1',
        );

        expect(store.hasHomeLocation, isFalse);
        expect(store.hasConfirmedHomeLocation, isFalse);
      },
    );

    test('clearAllForSession removes scoped and legacy keys', () async {
      await prefs.setDouble('chisto_home_latitude_user-1', 41.99);
      await prefs.setDouble('chisto_home_longitude_user-1', 21.43);
      await prefs.setString(
        'chisto_home_location_set_at_user-1',
        '2026-06-08T12:00:00.000Z',
      );
      await prefs.setDouble(kUserHomeLatitudeKey, 42.0);
      await prefs.setDouble(kUserHomeLongitudeKey, 21.5);

      await UserHomeLocationStore.clearAllForSession(prefs, userId: 'user-1');

      expect(prefs.getDouble('chisto_home_latitude_user-1'), isNull);
      expect(prefs.getDouble(kUserHomeLatitudeKey), isNull);
    });
  });
}
