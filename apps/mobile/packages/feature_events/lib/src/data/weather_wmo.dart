/// WMO Weather interpretation codes (WW) as returned by Open-Meteo `weathercode`.
///
/// See: https://open-meteo.com/en/docs (WMO Weather interpretation codes)
class WeatherWmo {
  WeatherWmo._();

  /// Short English label for UI (caller may replace with l10n later).
  static String description(int code) {
    return switch (code) {
      0 => 'Clear sky',
      1 => 'Mainly clear',
      2 => 'Partly cloudy',
      3 => 'Overcast',
      45 || 48 => 'Fog',
      51 => 'Light drizzle',
      53 => 'Moderate drizzle',
      55 => 'Dense drizzle',
      56 => 'Light freezing drizzle',
      57 => 'Dense freezing drizzle',
      61 => 'Slight rain',
      63 => 'Moderate rain',
      65 => 'Heavy rain',
      66 => 'Light freezing rain',
      67 => 'Heavy freezing rain',
      71 => 'Slight snow',
      73 => 'Moderate snow',
      75 => 'Heavy snow',
      77 => 'Snow grains',
      80 => 'Slight rain showers',
      81 => 'Moderate rain showers',
      82 => 'Violent rain showers',
      85 => 'Slight snow showers',
      86 => 'Heavy snow showers',
      95 => 'Thunderstorm',
      96 => 'Thunderstorm with slight hail',
      99 => 'Thunderstorm with heavy hail',
      _ => _legacyDescription(code),
    };
  }

  /// Older or undocumented codes: coarse buckets.
  static String _legacyDescription(int code) {
    if (code >= 1 && code <= 3) {
      return description(code);
    }
    if (code >= 4 && code <= 44) {
      return 'Fog';
    }
    if (code >= 50 && code <= 59) {
      return 'Drizzle';
    }
    if (code >= 60 && code <= 69) {
      return 'Rain';
    }
    if (code >= 70 && code <= 79) {
      return 'Snow';
    }
    if (code >= 80 && code <= 89) {
      return 'Rain showers';
    }
    if (code >= 90 && code <= 99) {
      return 'Thunderstorm';
    }
    return 'Weather';
  }

  /// Visual bucket for icon + tint (stable Material icons, codepoints in 0xe… range).
  static WeatherWmoVisual visual(int code) {
    return switch (code) {
      0 => WeatherWmoVisual.clear,
      1 => WeatherWmoVisual.mainlyClear,
      2 => WeatherWmoVisual.partlyCloudy,
      3 => WeatherWmoVisual.overcast,
      45 || 48 => WeatherWmoVisual.fog,
      >= 51 && <= 57 => WeatherWmoVisual.drizzle,
      >= 61 && <= 67 => WeatherWmoVisual.rain,
      >= 71 && <= 77 => WeatherWmoVisual.snow,
      >= 80 && <= 82 => WeatherWmoVisual.rainShowers,
      >= 85 && <= 86 => WeatherWmoVisual.snowShowers,
      >= 95 && <= 99 => WeatherWmoVisual.thunderstorm,
      _ => _legacyVisual(code),
    };
  }

  static WeatherWmoVisual _legacyVisual(int code) {
    if (code >= 1 && code <= 3) {
      return visual(code);
    }
    if (code >= 4 && code <= 49) {
      return WeatherWmoVisual.fog;
    }
    if (code >= 50 && code <= 59) {
      return WeatherWmoVisual.drizzle;
    }
    if (code >= 60 && code <= 69) {
      return WeatherWmoVisual.rain;
    }
    if (code >= 70 && code <= 79) {
      return WeatherWmoVisual.snow;
    }
    if (code >= 80 && code <= 89) {
      return WeatherWmoVisual.rainShowers;
    }
    if (code >= 90 && code <= 99) {
      return WeatherWmoVisual.thunderstorm;
    }
    return WeatherWmoVisual.overcast;
  }
}

enum WeatherWmoVisual {
  clear,
  mainlyClear,
  partlyCloudy,
  overcast,
  fog,
  drizzle,
  rain,
  snow,
  rainShowers,
  snowShowers,
  thunderstorm,
}
