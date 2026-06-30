import 'package:shared_preferences/shared_preferences.dart';

/// Legacy global keys (pre-user-scoping). Cleared on migration and sign-out.
const String kUserHomeLatitudeKey = 'chisto_home_latitude';
const String kUserHomeLongitudeKey = 'chisto_home_longitude';
const String kUserHomeLocationLabelKey = 'chisto_home_location_label';
const String kUserHomeLocationSetAtKey = 'chisto_home_location_set_at';

String _scopedHomeLatitudeKey(String userId) => 'chisto_home_latitude_$userId';
String _scopedHomeLongitudeKey(String userId) =>
    'chisto_home_longitude_$userId';
String _scopedHomeLocationLabelKey(String userId) =>
    'chisto_home_location_label_$userId';
String _scopedHomeLocationSetAtKey(String userId) =>
    'chisto_home_location_set_at_$userId';

/// Persists the user's server-confirmed home location for gate routing and map centering.
///
/// When [userId] is set, keys are scoped per account to prevent cross-user leakage.
class UserHomeLocationStore {
  UserHomeLocationStore(this._prefs, {String? userId}) : _userId = userId;

  final SharedPreferences _prefs;
  final String? _userId;

  String? get _activeUserId {
    final String? id = _userId;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  String get _latitudeKey => _activeUserId != null
      ? _scopedHomeLatitudeKey(_activeUserId!)
      : kUserHomeLatitudeKey;

  String get _longitudeKey => _activeUserId != null
      ? _scopedHomeLongitudeKey(_activeUserId!)
      : kUserHomeLongitudeKey;

  String get _labelKey => _activeUserId != null
      ? _scopedHomeLocationLabelKey(_activeUserId!)
      : kUserHomeLocationLabelKey;

  String get _setAtKey => _activeUserId != null
      ? _scopedHomeLocationSetAtKey(_activeUserId!)
      : kUserHomeLocationSetAtKey;

  double? get latitude => _prefs.getDouble(_latitudeKey);
  double? get longitude => _prefs.getDouble(_longitudeKey);
  String? get label => _prefs.getString(_labelKey);
  String? get homeLocationSetAt => _prefs.getString(_setAtKey);

  /// Coordinates present (may be unconfirmed / stale).
  bool get hasHomeLocation => latitude != null && longitude != null;

  /// Server confirmed home via `PATCH /auth/me/home-location` (`homeLocationSetAt` set).
  bool get hasConfirmedHomeLocation =>
      homeLocationSetAt != null &&
      homeLocationSetAt!.isNotEmpty &&
      latitude != null &&
      longitude != null;

  Future<void> save({
    required double latitude,
    required double longitude,
    String? label,
    required String homeLocationSetAt,
  }) async {
    await _migrateLegacyKeysIfNeeded();
    await _prefs.setDouble(_latitudeKey, latitude);
    await _prefs.setDouble(_longitudeKey, longitude);
    await _prefs.setString(_setAtKey, homeLocationSetAt);
    if (label != null && label.trim().isNotEmpty) {
      await _prefs.setString(_labelKey, label.trim());
    } else {
      await _prefs.remove(_labelKey);
    }
  }

  Future<void> clear() async {
    await _clearKeysForUser(_activeUserId);
    await _clearLegacyKeys();
  }

  /// Clears home location for [userId] plus all legacy global keys.
  static Future<void> clearAllForSession(
    SharedPreferences prefs, {
    String? userId,
  }) async {
    await _clearKeysForUserStatic(prefs, userId);
    await _clearLegacyKeysStatic(prefs);
  }

  Future<void> applyFromProfileJson(Map<String, dynamic> json) async {
    await _migrateLegacyKeysIfNeeded();

    final Object? setAtRaw = json['homeLocationSetAt'];
    final String? setAt = setAtRaw?.toString().trim();
    final Object? lat = json['homeLatitude'];
    final Object? lng = json['homeLongitude'];

    if (setAt == null || setAt.isEmpty || lat is! num || lng is! num) {
      await clear();
      return;
    }

    await save(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      label: json['homeLocationLabel'] as String?,
      homeLocationSetAt: setAt,
    );
  }

  /// Moves legacy global coords into scoped keys for the active user, then clears legacy.
  Future<void> _migrateLegacyKeysIfNeeded() async {
    final String? userId = _activeUserId;
    if (userId == null) return;

    final double? legacyLat = _prefs.getDouble(kUserHomeLatitudeKey);
    final double? legacyLng = _prefs.getDouble(kUserHomeLongitudeKey);
    if (legacyLat == null && legacyLng == null) return;

    final bool scopedEmpty =
        !_prefs.containsKey(_scopedHomeLatitudeKey(userId)) &&
        !_prefs.containsKey(_scopedHomeLongitudeKey(userId));

    if (scopedEmpty && legacyLat != null && legacyLng != null) {
      final String? legacySetAt = _prefs.getString(kUserHomeLocationSetAtKey);
      await _prefs.setDouble(_scopedHomeLatitudeKey(userId), legacyLat);
      await _prefs.setDouble(_scopedHomeLongitudeKey(userId), legacyLng);
      final String? legacyLabel = _prefs.getString(kUserHomeLocationLabelKey);
      if (legacyLabel != null) {
        await _prefs.setString(
          _scopedHomeLocationLabelKey(userId),
          legacyLabel,
        );
      }
      if (legacySetAt != null) {
        await _prefs.setString(
          _scopedHomeLocationSetAtKey(userId),
          legacySetAt,
        );
      }
    }

    await _clearLegacyKeys();
  }

  Future<void> _clearKeysForUser(String? userId) async {
    await _clearKeysForUserStatic(_prefs, userId);
  }

  static Future<void> _clearKeysForUserStatic(
    SharedPreferences prefs,
    String? userId,
  ) async {
    if (userId == null || userId.isEmpty) return;
    await prefs.remove(_scopedHomeLatitudeKey(userId));
    await prefs.remove(_scopedHomeLongitudeKey(userId));
    await prefs.remove(_scopedHomeLocationLabelKey(userId));
    await prefs.remove(_scopedHomeLocationSetAtKey(userId));
  }

  Future<void> _clearLegacyKeys() async {
    await _clearLegacyKeysStatic(_prefs);
  }

  static Future<void> _clearLegacyKeysStatic(SharedPreferences prefs) async {
    await prefs.remove(kUserHomeLatitudeKey);
    await prefs.remove(kUserHomeLongitudeKey);
    await prefs.remove(kUserHomeLocationLabelKey);
    await prefs.remove(kUserHomeLocationSetAtKey);
  }
}
