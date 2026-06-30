/// Labels for [DistanceFormatter] (wire to `AppLocalizations` at call sites).
abstract class SiteCardDistanceLabels {
  String meters(int meters);
  String kilometersShort(String formattedKm);
  String kilometersWhole(String formattedKm);
}

/// Unit-suffix style (`500 m`, `1.2 km`) used on site detail stats.
abstract class CommonUnitDistanceLabels {
  String metersWithUnit(int meters);
  String kilometersWithUnit(String formattedKm);
}

/// Formats pollution-site distances from kilometers (feed cards, detail stats).
class DistanceFormatter {
  const DistanceFormatter._();

  /// Site card / feed chip style (`siteCardDistanceMeters`, etc.).
  static String formatSiteCardKm(double km, SiteCardDistanceLabels labels) {
    if (km < 1) {
      final int meters = (km * 1000).round().clamp(1, 999);
      return labels.meters(meters);
    }
    if (km < 10) {
      return labels.kilometersShort(km.toStringAsFixed(1));
    }
    return labels.kilometersWhole(km.toStringAsFixed(0));
  }

  /// Site detail stats row (`500 m`, `1.2 km` with separate unit strings).
  static String formatCommonUnitKm(double km, CommonUnitDistanceLabels labels) {
    if (km < 1) {
      final int meters = (km * 1000).round().clamp(1, 999);
      return labels.metersWithUnit(meters);
    }
    if (km < 10) {
      return labels.kilometersWithUnit(km.toStringAsFixed(1));
    }
    return labels.kilometersWithUnit(km.toStringAsFixed(0));
  }
}
