import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shown over the map while GPS is resolving and the map center is not yet known.
class LocationPickerMapTilesFallback extends StatelessWidget {
  const LocationPickerMapTilesFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.inputFill, AppColors.divider],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: AppSpacing.iconLg,
              height: AppSpacing.iconLg,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Detecting location…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
