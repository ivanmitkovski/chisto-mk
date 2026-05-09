import 'package:flutter/material.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_selection_notifier.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class MapSearchCoordinator {
  const MapSearchCoordinator();

  Future<void> onSearchResultSelected({
    required BuildContext context,
    required WidgetRef ref,
    required PollutionSite site,
    required Map<String, LatLng> coordsById,
    required AnimatedMapController mapController,
    required SitesRepository sitesRepository,
  }) async {
    PollutionSite chosen = site;
    LatLng? point = coordsById[chosen.id];
    if (point == null &&
        chosen.latitude != null &&
        chosen.longitude != null) {
      point = LatLng(chosen.latitude!, chosen.longitude!);
    }
    if (point == null) {
      final PollutionSite? full = await sitesRepository.getSiteById(chosen.id);
      if (!context.mounted) {
        return;
      }
      if (full != null &&
          full.latitude != null &&
          full.longitude != null) {
        chosen = full;
        point = LatLng(full.latitude!, full.longitude!);
      }
    }
    if (point == null) {
      if (!context.mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.mapSearchLocationUnavailableSnack,
        type: AppSnackType.warning,
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    ref.read(mapSelectionNotifierProvider.notifier).select(chosen);
    AppHaptics.pinSelect(context);
    await mapController.animateTo(dest: point, zoom: 14.5);
  }
}
