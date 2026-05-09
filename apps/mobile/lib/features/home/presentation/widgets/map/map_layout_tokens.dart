import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class MapLayoutTokens {
  const MapLayoutTokens._();

  static const double markerSize = 68;
  static const double userDotSize = 80;

  static const int prefetchBudget = 44;

  static const EdgeInsets geoFitPadding =
      EdgeInsets.fromLTRB(44, 96, 44, 112);

  static const double previewHeightCompact = 240;
  static const double previewHeightWide = 280;
  static const double previewWidthBreakpoint = 600;

  static double previewHeight(double screenWidth) =>
      screenWidth > previewWidthBreakpoint
          ? previewHeightWide
          : previewHeightCompact;

  static const double zoomCity = 11;
  static const double minZoomClusterExpand = 15;
  static const double prefetchOverscanBasePt = 72;

  static const double clusterExpandPadding =
      AppSpacing.xxl + AppSpacing.lg;
  static const double geoFitMaxZoomCountry = 9.2;
  static const double geoFitMinZoomCountry = 7.6;
  static const double geoFitMaxZoomMunicipality = 13.8;
  static const double geoFitMinZoomMunicipality = 10.0;

  static double clusterMarkerSize(int count) =>
      (36 + 8 * math.sqrt(count)).clamp(38, 64);
}
