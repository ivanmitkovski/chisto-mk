import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Thin top indeterminate bar (Google Maps–style) used while tiles load.
class MapLoadingProgressBar extends StatelessWidget {
  const MapLoadingProgressBar({super.key, required this.isDarkMap});

  final bool isDarkMap;

  @override
  Widget build(BuildContext context) {
    final Color track = isDarkMap
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.black.withValues(alpha: 0.06);
    final Color value = isDarkMap
        ? AppColors.white.withValues(alpha: 0.55)
        : AppColors.primary.withValues(alpha: 0.85);
    return SizedBox(
      width: double.infinity,
      height: 2.5,
      child: ClipRect(
        child: LinearProgressIndicator(
          minHeight: 2.5,
          backgroundColor: track,
          valueColor: AlwaysStoppedAnimation<Color>(value),
        ),
      ),
    );
  }
}
