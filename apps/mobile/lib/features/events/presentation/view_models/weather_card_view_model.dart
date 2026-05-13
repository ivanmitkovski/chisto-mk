import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/features/events/data/weather_repository.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

/// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
class WeatherCardViewModel extends ChangeNotifier {
  WeatherCardViewModel({WeatherRepository? repository})
      : _repository = repository ?? WeatherRepository.instance;

  final WeatherRepository _repository;

  DayWeather? dayWeather;
  bool loading = true;
  bool failed = false;

  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load(EcoEvent event) async {
    loading = true;
    failed = false;
    _notifyIfAlive();
    final double? lat = event.siteLat;
    final double? lng = event.siteLng;
    if (lat == null || lng == null) {
      if (_disposed) return;
      loading = false;
      failed = true;
      dayWeather = null;
      _notifyIfAlive();
      return;
    }
    final DayWeather? result = await _repository.fetchForDate(
      lat: lat,
      lng: lng,
      targetDate: event.date,
      scheduledAtUtc: event.scheduledAtUtc,
    );
    if (_disposed) return;
    dayWeather = result;
    loading = false;
    failed = result == null;
    _notifyIfAlive();
  }
}
