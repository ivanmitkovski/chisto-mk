import 'package:feature_events/src/data/weather_repository.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weather_card_view_model.g.dart';

class WeatherCardState {
  const WeatherCardState({
    this.dayWeather,
    this.loading = true,
    this.failed = false,
  });

  final DayWeather? dayWeather;
  final bool loading;
  final bool failed;

  WeatherCardState copyWith({
    DayWeather? dayWeather,
    bool? loading,
    bool? failed,
  }) {
    return WeatherCardState(
      dayWeather: dayWeather ?? this.dayWeather,
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
    );
  }
}

/// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
@riverpod
class WeatherCardViewModel extends _$WeatherCardViewModel {
  bool _disposed = false;

  @override
  WeatherCardState build(EcoEvent event) {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    Future<void>.microtask(() => load(event));
    return const WeatherCardState();
  }

  Future<void> load(EcoEvent event) async {
    state = state.copyWith(loading: true, failed: false);
    final double? lat = event.siteLat;
    final double? lng = event.siteLng;
    if (lat == null || lng == null) {
      if (_disposed) return;
      state = state.copyWith(loading: false, failed: true, dayWeather: null);
      return;
    }
    final DayWeather? result = await WeatherRepository.instance.fetchForDate(
      lat: lat,
      lng: lng,
      targetDate: event.date,
      scheduledAtUtc: event.scheduledAtUtc,
    );
    if (_disposed) return;
    state = state.copyWith(
      dayWeather: result,
      loading: false,
      failed: result == null,
    );
  }
}
