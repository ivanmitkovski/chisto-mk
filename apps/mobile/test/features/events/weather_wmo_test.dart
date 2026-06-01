import 'package:feature_events/src/data/weather_wmo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherWmo.description', () {
    test('table-driven: known WMO codes', () {
      final List<({int code, String label})> cases =
          <({int code, String label})>[
            (code: 0, label: 'Clear sky'),
            (code: 1, label: 'Mainly clear'),
            (code: 2, label: 'Partly cloudy'),
            (code: 3, label: 'Overcast'),
            (code: 45, label: 'Fog'),
            (code: 48, label: 'Fog'),
            (code: 51, label: 'Light drizzle'),
            (code: 61, label: 'Slight rain'),
            (code: 71, label: 'Slight snow'),
            (code: 80, label: 'Slight rain showers'),
            (code: 95, label: 'Thunderstorm'),
            (code: 99, label: 'Thunderstorm with heavy hail'),
          ];
      for (final ({int code, String label}) c in cases) {
        expect(WeatherWmo.description(c.code), c.label);
      }
    });

    test('table-driven: legacy bucket codes', () {
      final List<({int code, String label})> cases =
          <({int code, String label})>[
            (code: 4, label: 'Fog'),
            (code: 44, label: 'Fog'),
            (code: 52, label: 'Drizzle'),
            (code: 59, label: 'Drizzle'),
            (code: 62, label: 'Rain'),
            (code: 69, label: 'Rain'),
            (code: 72, label: 'Snow'),
            (code: 79, label: 'Snow'),
            (code: 83, label: 'Rain showers'),
            (code: 89, label: 'Rain showers'),
            (code: 91, label: 'Thunderstorm'),
            (code: 98, label: 'Thunderstorm'),
          ];
      for (final ({int code, String label}) c in cases) {
        expect(WeatherWmo.description(c.code), c.label);
      }
    });

    test('unknown code falls back to Weather', () {
      expect(WeatherWmo.description(-1), 'Weather');
      expect(WeatherWmo.description(100), 'Weather');
    });
  });

  group('WeatherWmo.visual', () {
    test('table-driven: primary WMO codes', () {
      final List<({int code, WeatherWmoVisual visual})> cases =
          <({int code, WeatherWmoVisual visual})>[
            (code: 0, visual: WeatherWmoVisual.clear),
            (code: 1, visual: WeatherWmoVisual.mainlyClear),
            (code: 2, visual: WeatherWmoVisual.partlyCloudy),
            (code: 3, visual: WeatherWmoVisual.overcast),
            (code: 45, visual: WeatherWmoVisual.fog),
            (code: 53, visual: WeatherWmoVisual.drizzle),
            (code: 63, visual: WeatherWmoVisual.rain),
            (code: 75, visual: WeatherWmoVisual.snow),
            (code: 81, visual: WeatherWmoVisual.rainShowers),
            (code: 86, visual: WeatherWmoVisual.snowShowers),
            (code: 96, visual: WeatherWmoVisual.thunderstorm),
          ];
      for (final ({int code, WeatherWmoVisual visual}) c in cases) {
        expect(WeatherWmo.visual(c.code), c.visual);
      }
    });

    test('table-driven: legacy visual buckets', () {
      final List<({int code, WeatherWmoVisual visual})> cases =
          <({int code, WeatherWmoVisual visual})>[
            (code: 4, visual: WeatherWmoVisual.fog),
            (code: 49, visual: WeatherWmoVisual.fog),
            (code: 58, visual: WeatherWmoVisual.drizzle),
            (code: 68, visual: WeatherWmoVisual.rain),
            (code: 78, visual: WeatherWmoVisual.snow),
            (code: 88, visual: WeatherWmoVisual.rainShowers),
            (code: 94, visual: WeatherWmoVisual.thunderstorm),
          ];
      for (final ({int code, WeatherWmoVisual visual}) c in cases) {
        expect(WeatherWmo.visual(c.code), c.visual);
      }
    });

    test('unknown code falls back to overcast', () {
      expect(WeatherWmo.visual(-1), WeatherWmoVisual.overcast);
      expect(WeatherWmo.visual(100), WeatherWmoVisual.overcast);
    });
  });
}
