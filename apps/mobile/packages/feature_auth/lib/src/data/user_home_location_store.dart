import 'package:shared_preferences/shared_preferences.dart';

const String kUserHomeLatitudeKey = 'chisto_home_latitude';
const String kUserHomeLongitudeKey = 'chisto_home_longitude';
const String kUserHomeLocationLabelKey = 'chisto_home_location_label';

class UserHomeLocationStore {
  UserHomeLocationStore(this._prefs);

  final SharedPreferences _prefs;

  double? get latitude => _prefs.getDouble(kUserHomeLatitudeKey);
  double? get longitude => _prefs.getDouble(kUserHomeLongitudeKey);
  String? get label => _prefs.getString(kUserHomeLocationLabelKey);

  bool get hasHomeLocation => latitude != null && longitude != null;

  Future<void> save({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    await _prefs.setDouble(kUserHomeLatitudeKey, latitude);
    await _prefs.setDouble(kUserHomeLongitudeKey, longitude);
    if (label != null && label.trim().isNotEmpty) {
      await _prefs.setString(kUserHomeLocationLabelKey, label.trim());
    } else {
      await _prefs.remove(kUserHomeLocationLabelKey);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(kUserHomeLatitudeKey);
    await _prefs.remove(kUserHomeLongitudeKey);
    await _prefs.remove(kUserHomeLocationLabelKey);
  }

  Future<void> applyFromProfileJson(Map<String, dynamic> json) async {
    final Object? lat = json['homeLatitude'];
    final Object? lng = json['homeLongitude'];
    if (lat is! num || lng is! num) {
      return;
    }
    await save(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      label: json['homeLocationLabel'] as String?,
    );
  }
}
