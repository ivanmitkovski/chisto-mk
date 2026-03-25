import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Single source of truth for Macedonia report bounds (axis-aligned box).
/// Use for geofence checks and clamping in location picker and validation.
class ReportGeoFence {
  ReportGeoFence._();

  static const double minLat = 40.8;
  static const double maxLat = 42.4;
  static const double minLng = 20.4;
  static const double maxLng = 23.1;

  /// Default center when no location is set (e.g. map initial view).
  static const double centerLat = 41.6086;
  static const double centerLng = 21.7453;

  /// Inset from edges when snapping back so the pin stays clearly inside.
  static const double boundaryInset = 0.02;

  static double get insetMinLat => minLat + boundaryInset;
  static double get insetMaxLat => maxLat - boundaryInset;
  static double get insetMinLng => minLng + boundaryInset;
  static double get insetMaxLng => maxLng - boundaryInset;

  static bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Clamps (lat, lng) to the inset bounds so the point is safely inside.
  static (double lat, double lng) clampToInsetBounds(double lat, double lng) {
    final double clampedLat = lat.clamp(insetMinLat, insetMaxLat);
    final double clampedLng = lng.clamp(insetMinLng, insetMaxLng);
    return (clampedLat, clampedLng);
  }
}

bool isReportLocationInMacedonia(double lat, double lng) =>
    ReportGeoFence.contains(lat, lng);

enum ReportCategory {
  illegalLandfill(
    'Illegal landfill',
    'Dumped waste, trash piles, or informal disposal sites.',
    Icons.delete_outline_rounded,
  ),
  waterPollution(
    'Water pollution',
    'Contaminated rivers, lakes, drains, or wastewater discharge.',
    Icons.water_drop_outlined,
  ),
  airPollution(
    'Air pollution',
    'Smoke, dust, burning waste, or emissions harming air quality.',
    Icons.air_rounded,
  ),
  industrialWaste(
    'Industrial waste',
    'Construction debris, factory waste, or hazardous materials.',
    Icons.factory_rounded,
  ),
  other(
    'Other',
    'Use when the issue does not clearly match the categories above.',
    Icons.more_horiz_rounded,
  );

  const ReportCategory(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;

  static ReportCategory? fromApiString(String? s) {
    if (s == null || s.isEmpty) return null;
    return switch (s.toUpperCase()) {
      'ILLEGAL_LANDFILL' => ReportCategory.illegalLandfill,
      'WATER_POLLUTION' => ReportCategory.waterPollution,
      'AIR_POLLUTION' => ReportCategory.airPollution,
      'INDUSTRIAL_WASTE' => ReportCategory.industrialWaste,
      'OTHER' => ReportCategory.other,
      _ => null,
    };
  }

  String get apiString => switch (this) {
        ReportCategory.illegalLandfill => 'ILLEGAL_LANDFILL',
        ReportCategory.waterPollution => 'WATER_POLLUTION',
        ReportCategory.airPollution => 'AIR_POLLUTION',
        ReportCategory.industrialWaste => 'INDUSTRIAL_WASTE',
        ReportCategory.other => 'OTHER',
      };
}

/// Canonical pollution types for filtering and reporting (aligned with ReportCategory).
List<String> get reportPollutionTypeLabels =>
    ReportCategory.values.map((ReportCategory c) => c.label).toList();

enum ReportRequirement {
  photos('Add at least one photo'),
  category('Choose a category'),
  location('Confirm a location in Macedonia');

  const ReportRequirement(this.message);
  final String message;
}

enum CleanupEffort {
  oneToTwo('1–2 people'),
  threeToFive('3–5 people'),
  sixToTen('6–10 people'),
  tenPlus('10+ people'),
  notSure('Not sure');

  const CleanupEffort(this.label);
  final String label;

  /// API / Prisma enum key (POST /reports `cleanupEffort`).
  String get apiKey => switch (this) {
        CleanupEffort.oneToTwo => 'ONE_TO_TWO',
        CleanupEffort.threeToFive => 'THREE_TO_FIVE',
        CleanupEffort.sixToTen => 'SIX_TO_TEN',
        CleanupEffort.tenPlus => 'TEN_PLUS',
        CleanupEffort.notSure => 'NOT_SURE',
      };

  static CleanupEffort? fromApiString(String? s) {
    if (s == null || s.isEmpty) return null;
    return switch (s) {
      'ONE_TO_TWO' => CleanupEffort.oneToTwo,
      'THREE_TO_FIVE' => CleanupEffort.threeToFive,
      'SIX_TO_TEN' => CleanupEffort.sixToTen,
      'TEN_PLUS' => CleanupEffort.tenPlus,
      'NOT_SURE' => CleanupEffort.notSure,
      _ => null,
    };
  }
}

class ReportDraft {
  ReportDraft({
    List<XFile>? photos,
    this.category,
    this.description = '',
    this.latitude,
    this.longitude,
    this.address,
    this.cleanupEffort,
    this.severity = 3,
  }) : photos = photos ?? <XFile>[];

  final List<XFile> photos;
  final ReportCategory? category;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? address;
  final CleanupEffort? cleanupEffort;
  final int severity;

  bool get hasPhotos => photos.isNotEmpty;
  bool get hasCategory => category != null;
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasDescription => description.trim().isNotEmpty;

  bool get isValid => hasPhotos && hasCategory && hasLocation;

  int get completedRequiredSteps => <bool>[
    hasPhotos,
    hasCategory,
    hasLocation,
  ].where((bool value) => value).length;

  int get totalRequiredSteps => 3;

  List<ReportRequirement> missingRequirements({
    required bool hasLocationInMacedonia,
  }) {
    final List<ReportRequirement> missing = <ReportRequirement>[];
    if (!hasPhotos) missing.add(ReportRequirement.photos);
    if (!hasCategory) missing.add(ReportRequirement.category);
    if (!hasLocationInMacedonia) missing.add(ReportRequirement.location);
    return missing;
  }

  ReportDraft copyWith({
    List<XFile>? photos,
    ReportCategory? category,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    CleanupEffort? cleanupEffort,
    int? severity,
    bool clearLocation = false,
  }) {
    if (clearLocation) {
      return ReportDraft(
        photos: photos ?? this.photos,
        category: category ?? this.category,
        description: description ?? this.description,
        latitude: null,
        longitude: null,
        address: null,
        cleanupEffort: this.cleanupEffort,
        severity: severity ?? this.severity,
      );
    }
    return ReportDraft(
      photos: photos ?? this.photos,
      category: category ?? this.category,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      cleanupEffort: cleanupEffort ?? this.cleanupEffort,
      severity: severity ?? this.severity,
    );
  }
}
