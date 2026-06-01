/// Tunable timing / geometry for [VoiceRecordingMeter] (documented for product iteration).
abstract final class VoiceRecordingConstants {
  static const Duration amplitudeSampleInterval = Duration(milliseconds: 72);

  /// Seconds per column shift when scrolling the level history.
  static const double scrollPeriodSeconds = 0.034;

  static const double dbMin = -52;
  static const double dbMax = -4;

  static const double followUpRate = 24;
  static const double followDownRate = 16;

  static const double maxBarHeight = 26;
  static const double minBarHeight = 3;
  static const double barSpacing = 2;
}
