import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2FD788);
  static const Color primaryDark = Color(0xFF14B96A);
  static const Color appBackground = Color(0xFFF4F5F7);
  /// Base tone behind raster map tiles (Carto light); avoids default FlutterMap grey (#E0E0E0).
  static const Color mapLightPaper = Color(0xFFF5F3F0);
  /// Base tone behind Carto dark tiles while pixels load.
  static const Color mapDarkPaper = Color(0xFF1A1A1A);
  static const Color panelBackground = Color(0xFFFFFFFF);

  /// Slightly lifted surface for iOS-style grouped lists on [appBackground] (event detail).
  static const Color detailSurfaceGrouped = Color(0xFFE8EAEF);

  /// Raised module on detail canvas (weather, participants, etc.); keep readable with body text.
  static const Color detailSurfaceModule = inputFill;
  static const Color textPrimary = Color(0xFF121212);
  static const Color textSecondary = Color(0xFF4C4C4C);
  static const Color textMuted = Color(0xFF7A7A7A);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xB3FFFFFF);
  static const Color inputFill = Color(0xFFF0F1F7);
  static const Color inputBorder = Color(0xFFDDE1EA);
  static const Color accentDanger = Color(0xFFE6513D);
  static const Color accentWarning = Color(0xFFF5A623);
  /// Organizer highlights / charts — alias of [accentWarning] for semantic call sites.
  static Color get warningAccent => accentWarning;
  static const Color accentWarningDark = Color(0xFFD4910C);
  static const Color accentInfo = Color(0xFF3BA3F7);
  static const Color divider = Color(0xFFE5E7ED);

  /// Reports vertical — softened dividers (avoid ad-hoc [withValues] at call sites).
  static Color get reportDividerLight => divider.withValues(alpha: 0.5);
  static Color get reportDividerMedium => divider.withValues(alpha: 0.7);
  static Color get reportDividerStrong => divider.withValues(alpha: 0.8);
  static Color get reportDisabledPrimaryFill => primary.withValues(alpha: 0.42);

  /// Selected discovery pill / chip fill (home feed + events: [AppFilterPillBar] feedChip).
  static Color get feedPillSelectedFill =>
      primaryDark.withValues(alpha: 0.12);

  /// Selected discovery pill border (matches feed chip outline weight).
  static Color get feedPillSelectedBorder =>
      primaryDark.withValues(alpha: 0.35);

  /// Text and icons on [feedPillSelectedFill].
  static const Color feedPillSelectedForeground = primaryDark;

  static const Color overlay = Color(0x80000000);
  static const Color error = Color(0xFFD73636);

  // ---------------------------------------------------------------------------
  // Reports vertical — soft surfaces (chips, banners, info callouts; light only)
  // ---------------------------------------------------------------------------

  /// Shared mint fill for approved chip and success [ReportInfoBanner] tone.
  static const Color reportSurfaceMint = Color(0xFFEDFFF6);

  /// Status chip backgrounds ([ReportSheetStatus]).
  static const Color reportChipUnderReviewFill = Color(0xFFFFF8EC);
  static const Color reportChipApprovedFill = reportSurfaceMint;
  static const Color reportChipDeclinedFill = Color(0xFFFFF0EE);
  static const Color reportChipLinkedFill = Color(0xFFEDF3FF);

  /// Success / warning / danger banner tones ([ReportSurfaceTone]).
  static const Color reportBannerSuccessBackground = reportSurfaceMint;
  static const Color reportBannerSuccessBorder = Color(0xFFD0F0DF);
  static const Color reportBannerSuccessIconBackground = Color(0xFFDDF7E9);
  static const Color reportBannerWarningBackground = Color(0xFFFFF6E8);
  static const Color reportBannerWarningBorder = Color(0xFFFFE1B3);
  static const Color reportBannerWarningIconBackground = Color(0xFFFFEDC8);
  static const Color reportBannerDangerBackground = Color(0xFFFFF1F0);
  static const Color reportBannerDangerBorder = Color(0xFFF7D2CF);
  static const Color reportBannerDangerIconBackground = Color(0xFFFDE3E1);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  static const Color shadowLight = Color(0x08000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color glassTint = Color(0x33FFFFFF);
  static const Color glassDark = Color(0xB3000000);
  static const Color scrim = Color(0x29000000);

  static const List<Color> avatarPalette = <Color>[
    Color(0xFF2FD788),
    Color(0xFF3BA3F7),
    Color(0xFFF5A623),
    Color(0xFFE6513D),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
  ];
}
