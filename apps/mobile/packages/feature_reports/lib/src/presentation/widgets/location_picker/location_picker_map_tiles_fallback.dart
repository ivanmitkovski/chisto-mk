import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shown over the map while GPS is resolving and the map center is not yet known.
class LocationPickerMapTilesFallback extends StatelessWidget {
  const LocationPickerMapTilesFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
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
            const SizedBox(
              width: AppSpacing.iconLg,
              height: AppSpacing.iconLg,
              child: AppLoadingIndicator(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.authLocationDetecting,
              style: AppTypographySurfaces.reportsLocationPickerCaption(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
