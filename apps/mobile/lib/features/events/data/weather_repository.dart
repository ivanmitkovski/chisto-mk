import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Forecast data for a single day returned by the Open-Meteo API.
class DayWeather {
  const DayWeather({
    required this.date,
    required this.wmoCode,
    required this.maxTempC,
    required this.minTempC,
    required this.precipitationMm,
    this.precipitationProbabilityMax,
  });

  /// Calendar date for this forecast (UTC midnight of the forecast day).
  final DateTime date;

  /// WMO weather interpretation code (0 = clear sky, see Open-Meteo docs).
  final int wmoCode;

  /// Maximum temperature in °C.
  final double maxTempC;

  /// Minimum temperature in °C.
  final double minTempC;

  /// Total precipitation in mm.
  final double precipitationMm;

  /// Daily max precipitation probability (0–100), when provided by the API.
  final int? precipitationProbabilityMax;
}

/// Fetches short-range daily weather from Open-Meteo (free, no API key).
///
/// Results are cached in [SharedPreferences] per `(lat, lng, date)` for 3 hours
/// to avoid redundant network calls when the user opens the detail screen multiple times.
class WeatherRepository {
  WeatherRepository._();

  static final WeatherRepository _instance = WeatherRepository._();
  static WeatherRepository get instance => _instance;

  static const Duration _cacheTtl = Duration(hours: 3);
  static const String _prefPrefix = 'weather_cache_v2_';

  static const Map<String, String> _httpHeaders = <String, String>{
    'User-Agent': 'Chisto.mk-Mobile/1.0 (+https://chisto.mk)',
  };

  /// Fetches weather for [lat]/[lng] for the calendar day that best matches the event.
  ///
  /// When [scheduledAtUtc] is set, the forecast day is derived from that instant using a
  /// longitude-based offset (≈ solar time). This aligns the request with Open-Meteo’s
  /// `timezone=auto` daily buckets better than the viewer’s local [targetDate] alone.
  ///
  /// Returns null on any error — weather is non-critical UI.
  Future<DayWeather?> fetchForDate({
    required double lat,
    required double lng,
    required DateTime targetDate,
    DateTime? scheduledAtUtc,
  }) async {
    final String dateStr = _forecastCalendarDate(
      siteLongitude: lng,
      scheduledAtUtc: scheduledAtUtc,
      fallbackLocalCalendarDate: targetDate,
    );
    final String cacheKey = _cacheKey(lat, lng, dateStr);
    final DayWeather? cached = await _readCache(cacheKey);
    if (cached != null) return cached;

    DayWeather? weather;
    try {
      weather = await _fetchFromOpenMeteoForecast(
        lat: lat,
        lng: lng,
        dateStr: dateStr,
      );
    } on Object {
      weather = null;
    }

    if (weather == null && _isHistoricalCalendarDate(dateStr)) {
      try {
        weather = await _fetchFromOpenMeteoArchive(
          lat: lat,
          lng: lng,
          dateStr: dateStr,
        );
      } on Object {
        weather = null;
      }
    }

    if (weather != null) {
      await _writeCache(cacheKey, weather);
    }
    return weather;
  }

  /// Open-Meteo’s forecast endpoint only covers a limited window; past
  /// calendar days need the archive API instead.
  static bool _isHistoricalCalendarDate(String isoDate) {
    final DateTime requested = _dateFromIsoDate(isoDate);
    final DateTime now = DateTime.now().toUtc();
    final DateTime todayStart = DateTime.utc(now.year, now.month, now.day);
    return requested.isBefore(todayStart);
  }

  Future<DayWeather?> _fetchFromOpenMeteoForecast({
    required double lat,
    required double lng,
    required String dateStr,
  }) async {
    final Uri uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${lat.toStringAsFixed(4)}'
      '&longitude=${lng.toStringAsFixed(4)}'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,'
      'precipitation_probability_max,weathercode'
      '&timezone=auto'
      '&start_date=$dateStr'
      '&end_date=$dateStr',
    );

    final http.Response response = await http
        .get(uri, headers: _httpHeaders)
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) return null;

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (body['error'] == true) return null;

    final Map<String, dynamic>? daily = body['daily'] as Map<String, dynamic>?;
    if (daily == null) return null;

    return _parseDailyDayWeather(daily, dateStr);
  }

  Future<DayWeather?> _fetchFromOpenMeteoArchive({
    required double lat,
    required double lng,
    required String dateStr,
  }) async {
    final Uri uri = Uri.parse(
      'https://archive-api.open-meteo.com/v1/archive'
      '?latitude=${lat.toStringAsFixed(4)}'
      '&longitude=${lng.toStringAsFixed(4)}'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,'
      'precipitation_probability_max,weathercode'
      '&timezone=auto'
      '&start_date=$dateStr'
      '&end_date=$dateStr',
    );

    final http.Response response = await http
        .get(uri, headers: _httpHeaders)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (body['error'] == true) return null;

    final Map<String, dynamic>? daily = body['daily'] as Map<String, dynamic>?;
    if (daily == null) return null;

    return _parseDailyDayWeather(daily, dateStr);
  }

  static DayWeather? _parseDailyDayWeather(
    Map<String, dynamic> daily,
    String dateStr,
  ) {
    final List<dynamic>? dates = daily['time'] as List<dynamic>?;
    final List<dynamic>? maxTemps = daily['temperature_2m_max'] as List<dynamic>?;
    final List<dynamic>? minTemps = daily['temperature_2m_min'] as List<dynamic>?;
    final List<dynamic>? precips = daily['precipitation_sum'] as List<dynamic>?;
    final List<dynamic>? probMax =
        daily['precipitation_probability_max'] as List<dynamic>?;
    final List<dynamic>? codes = daily['weathercode'] as List<dynamic>?;

    if (dates == null || dates.isEmpty) return null;

    final num? maxRaw = maxTemps?.first as num?;
    final num? minRaw = minTemps?.first as num?;
    if (maxRaw == null || minRaw == null) return null;

    final int? wmo = (codes?.first as num?)?.toInt();
    final int? prob = (probMax?.first as num?)?.toInt();

    return DayWeather(
      date: _dateFromIsoDate(dateStr),
      wmoCode: wmo ?? 0,
      maxTempC: maxRaw.toDouble(),
      minTempC: minRaw.toDouble(),
      precipitationMm: (precips?.first as num?)?.toDouble() ?? 0,
      precipitationProbabilityMax: prob?.clamp(0, 100),
    );
  }

  /// Open-Meteo uses `YYYY-MM-DD` for daily rows; interpret as UTC calendar day.
  static DateTime _dateFromIsoDate(String iso) {
    final List<String> p = iso.split('-');
    if (p.length != 3) {
      return DateTime.utc(1970);
    }
    final int y = int.tryParse(p[0]) ?? 1970;
    final int m = int.tryParse(p[1]) ?? 1;
    final int d = int.tryParse(p[2]) ?? 1;
    return DateTime.utc(y, m, d);
  }

  /// ~15° longitude ≈ 1 hour solar offset; clamp to plausible offsets.
  static String _forecastCalendarDate({
    required double siteLongitude,
    DateTime? scheduledAtUtc,
    required DateTime fallbackLocalCalendarDate,
  }) {
    if (scheduledAtUtc != null) {
      final double offsetHours = (siteLongitude / 15.0).clamp(-12.0, 14.0);
      final Duration approxLocalOffset = Duration(
        seconds: (offsetHours * 3600).round(),
      );
      final DateTime shifted = scheduledAtUtc.toUtc().add(approxLocalOffset);
      return _isoDateUtc(shifted);
    }
    return _isoDateLocal(fallbackLocalCalendarDate);
  }

  static String _isoDateUtc(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _isoDateLocal(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _cacheKey(double lat, double lng, String isoDate) =>
      '$_prefPrefix${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_$isoDate';

  Future<DayWeather?> _readCache(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(key);
      if (raw == null) return null;
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      final int? savedAt = map['_savedAt'] as int?;
      if (savedAt == null) return null;
      final DateTime cacheTime =
          DateTime.fromMillisecondsSinceEpoch(savedAt, isUtc: true);
      if (DateTime.now().toUtc().difference(cacheTime) > _cacheTtl) {
        unawaited(prefs.remove(key));
        return null;
      }
      final Object? probRaw = map['precipitationProbabilityMax'];
      return DayWeather(
        date: DateTime.parse(map['date'] as String),
        wmoCode: (map['wmoCode'] as num).toInt(),
        maxTempC: (map['maxTempC'] as num).toDouble(),
        minTempC: (map['minTempC'] as num).toDouble(),
        precipitationMm: (map['precipitationMm'] as num).toDouble(),
        precipitationProbabilityMax: probRaw is num ? probRaw.toInt() : null,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _writeCache(String key, DayWeather w) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> payload = <String, dynamic>{
        '_savedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
        'date': w.date.toIso8601String(),
        'wmoCode': w.wmoCode,
        'maxTempC': w.maxTempC,
        'minTempC': w.minTempC,
        'precipitationMm': w.precipitationMm,
      };
      if (w.precipitationProbabilityMax != null) {
        payload['precipitationProbabilityMax'] =
            w.precipitationProbabilityMax;
      }
      await prefs.setString(key, jsonEncode(payload));
    } on Object {
      // Cache write failure is non-fatal.
    }
  }
}
